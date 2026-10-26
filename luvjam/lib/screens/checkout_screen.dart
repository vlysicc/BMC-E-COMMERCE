import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/payment_service.dart';
import 'xendit_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cartItems,
  });

  final List<Map<String, dynamic>> cartItems;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  static const Color checkoutBackground = Color(0xFF101010);
  static const Color checkoutCard = Color(0xFF1B1B1B);
  static const Color checkoutGold = Color(0xFFD4AF70);
  static const Color checkoutWhite = Color(0xFFF5F5F5);
  static const Color checkoutMuted = Color(0xFFAAAAAA);

  bool _loadingProfile = true;
  bool _saving = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to continue.');
      }

      
    final profile = await _supabase
        .from('user_profiles')
        .select('full_name, phone, shipping_address')
        .eq('user_id', user.id)
        .maybeSingle();


      if (!mounted) return;

      if (profile != null) {
        _nameController.text = profile['full_name']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _addressController.text =
            profile['shipping_address']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = _cleanError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again before checking out.');
    }

    await _supabase.from('user_profiles').upsert({
    'user_id': user.id,
    'full_name': _nameController.text.trim(),
    'phone': _phoneController.text.trim(),
    'shipping_address': _addressController.text.trim(),
    }, onConflict: 'user_id');

  }

  List<Map<String, dynamic>> _prepareCartItems() {
    if (widget.cartItems.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    return widget.cartItems.map((item) {
      final productId = item['product_id'] ?? item['id'];
      final color = item['selected_color'] ?? item['color'];
      final size = item['selected_size'] ?? item['size'];
      final quantity = item['quantity'];

      if (productId == null ||
          color == null ||
          size == null ||
          quantity == null) {
        throw Exception(
          'A cart item is missing its product ID, color, size, or quantity.',
        );
      }

      if (quantity is! num ||
          quantity <= 0 ||
          quantity != quantity.toInt()) {
        throw Exception('A cart item has an invalid quantity.');
      }

      return <String, dynamic>{
        'product_id': productId,
        'quantity': quantity.toInt(),
        'selected_color': color.toString(),
        'selected_size': size.toString(),
      };
    }).toList();
  }

  Future<void> _placeOrder() async {
    if (_loadingProfile || _saving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _profileError = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please log in again before checking out.');
      }

      // Save the latest shipping details before creating the order.
      await _saveProfile();

      // Only send the fields expected by the create-order Edge Function.
      final items = _prepareCartItems();

      final result = await PaymentService().createCheckout(
        items: items,
      );

      if (!mounted) return;

      // Open the Xendit hosted checkout page inside the app.
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => XenditWebViewScreen(
           checkoutUrl: result.checkoutUrl.toString(),
            orderId: result.orderId,
          ),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: checkoutCard,
          content: Text(
            'Returned from checkout for order '
            '#${result.orderId ?? 'pending'}. '
            'Payment status must still be verified by the server.',
            style: const TextStyle(color: checkoutWhite),
          ),
        ),
      );
    } on FunctionException catch (e) {
      if (!mounted) return;

      final details = e.details;
      final serverMessage =
          details is Map ? details['error']?.toString() : null;

      setState(() {
        _profileError = serverMessage ??
            'Checkout error (${e.status}): '
                '${e.reasonPhrase ?? 'Please try again.'}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profileError = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  double _displaySubtotal() {
    // Display-only estimate. The server calculates the authoritative total.
    return widget.cartItems.fold<double>(0, (total, item) {
      final rawPrice = item['price'];
      final rawQuantity = item['quantity'];

      final price = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

      final quantity = rawQuantity is num
          ? rawQuantity.toInt()
          : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;

      return total + (price * quantity);
    });
  }

  String _peso(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: checkoutGold),
      labelStyle: const TextStyle(color: checkoutMuted),
      hintStyle: const TextStyle(color: checkoutMuted),
      filled: true,
      fillColor: checkoutBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: checkoutGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: checkoutCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SHIPPING INFORMATION',
              style: TextStyle(
                color: checkoutGold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: checkoutWhite),
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                label: 'Full name',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: checkoutWhite),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Phone number',
                icon: Icons.phone_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number.';
                }

                if (value.trim().length < 7) {
                  return 'Please enter a valid phone number.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: checkoutWhite),
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(
                label: 'Complete shipping address',
                icon: Icons.location_on_outlined,
                hint: 'House number, street, barangay, city',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your shipping address.';
                }

                if (value.trim().length < 8) {
                  return 'Please enter a more complete address.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = _displaySubtotal();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: checkoutCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER SUMMARY',
            style: TextStyle(
              color: checkoutGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.cartItems.isEmpty)
            const Text(
              'Your cart is empty.',
              style: TextStyle(color: checkoutMuted),
            )
          else
            ...widget.cartItems.map((item) {
              final name = (item['name'] ??
                      item['product_name'] ??
                      'Product')
                  .toString();

              final quantity = item['quantity'] ?? 1;
              final rawPrice = item['price'];
              final price = rawPrice is num
                  ? rawPrice.toDouble()
                  : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

              final color =
                  (item['selected_color'] ?? item['color'] ?? '').toString();
              final size =
                  (item['selected_size'] ?? item['size'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: checkoutWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: $quantity'
                            '${color.isNotEmpty ? ' • $color' : ''}'
                            '${size.isNotEmpty ? ' • $size' : ''}',
                            style: const TextStyle(
                              color: checkoutMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _peso(price *
                          (quantity is num
                              ? quantity.toDouble()
                              : double.tryParse(quantity.toString()) ?? 0)),
                      style: const TextStyle(
                        color: checkoutWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: Colors.white12, height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estimated subtotal',
                  style: TextStyle(color: checkoutMuted),
                ),
              ),
              Text(
                _peso(subtotal),
                style: const TextStyle(
                  color: checkoutWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Final amount is calculated by the server. Shipping fees, if any, '
            'must be handled by your order/payment setup.',
            style: TextStyle(
              color: checkoutMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_profileError == null || _profileError!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _profileError!,
              style: const TextStyle(
                color: Colors.redAccent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loadingProfile || _saving ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: checkoutGold,
          disabledBackgroundColor: checkoutGold.withValues(alpha: 0.4),
          foregroundColor: checkoutBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: checkoutBackground,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 10),
                  Text(
                    'CONTINUE TO PAYMENT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: checkoutBackground,
      appBar: AppBar(
        backgroundColor: checkoutBackground,
        foregroundColor: checkoutWhite,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: checkoutWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: checkoutGold),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Almost yours.',
                      style: TextStyle(
                        color: checkoutWhite,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Confirm your shipping details to continue.',
                      style: TextStyle(
                        color: checkoutMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildProfileForm(),
                    const SizedBox(height: 18),
                    _buildOrderSummary(),
                    const SizedBox(height: 18),
                    _buildErrorMessage(),
                    if (_profileError != null)
                      const SizedBox(height: 12),
                    _buildCheckoutButton(),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Secure checkout powered by Xendit',
                        style: TextStyle(
                          color: checkoutMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
