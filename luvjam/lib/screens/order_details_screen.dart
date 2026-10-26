import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color detailBlack = Color(0xFF101010);
const Color detailCard = Color(0xFF191919);
const Color detailGold = Color(0xFFD6B875);
const Color detailGoldLight = Color(0xFFF0DDA5);
const Color detailWhite = Color(0xFFF7F5EF);
const Color detailMuted = Color(0xFFAAA69B);
const Color detailBorder = Color(0xFF34312A);

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final result = await Supabase.instance.client
          .from('order_items')
          .select(
            'product_name, unit_price, quantity, selected_color, selected_size',
          )
          .eq('order_id', widget.order['id']);

      if (!mounted) return;

      setState(() {
        _items = List<Map<String, dynamic>>.from(result);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Order details error: $e');

      if (!mounted) return;

      setState(() {
        _error = 'Could not load order items. Please try again.';
        _loading = false;
      });
    }
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    return '₱${amount.toStringAsFixed(2)}';
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'PROCESSING':
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF83C99A);
      case 'EXPIRED':
      case 'CANCELLED':
      case 'FAILED':
        return const Color(0xFFFF8585);
      default:
        return detailGold;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'PROCESSING':
      case 'COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF1D3025);
      case 'EXPIRED':
      case 'CANCELLED':
      case 'FAILED':
        return const Color(0xFF351F1F);
      default:
        return const Color(0xFF302A1C);
    }
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: detailGoldLight,
              letterSpacing: 1.6,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: detailMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: detailMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: detailWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: detailMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(17),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: detailCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: detailBorder),
      ),
      child: child,
    );
  }

  Widget _buildOrderOverview(
    Map<String, dynamic> order,
    String total,
    String payment,
    String status,
  ) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF302A1C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: detailGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER REFERENCE',
                      style: TextStyle(
                        color: detailMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '#${order['id']}',
                      style: const TextStyle(
                        color: detailWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(height: 1, color: detailBorder),
          const SizedBox(height: 15),
          const Text(
            'TOTAL AMOUNT',
            style: TextStyle(
              color: detailMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            total,
            style: const TextStyle(
              color: detailGoldLight,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _statusBadge('PAYMENT STATUS', payment),
              _statusBadge('ORDER STATUS', status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final name = item['product_name']?.toString() ?? 'Product';
    final price = _number(item['unit_price']);
    final quantity = _number(item['quantity']);
    final subtotal = price * quantity;
    final color = item['selected_color']?.toString() ?? '-';
    final size = item['selected_size']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detailCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: detailBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF302A1C),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: detailGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: detailWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$color • Size $size',
                      style: const TextStyle(
                        color: detailMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: detailBorder),
          const SizedBox(height: 9),
          _infoRow('Unit Price', _money(item['unit_price'])),
          _infoRow('Quantity', quantity.toStringAsFixed(
            quantity == quantity.truncateToDouble() ? 0 : 2,
          )),
          const SizedBox(height: 10),
          Container(height: 1, color: detailBorder),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUBTOTAL',
                style: TextStyle(
                  color: detailMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _money(subtotal),
                style: const TextStyle(
                  color: detailGoldLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(Map<String, dynamic> order) {
    return _panel(
      child: Column(
        children: [
          _infoRow(
            'Customer',
            order['customer_name']?.toString() ?? '-',
          ),
          Container(height: 1, color: detailBorder),
          _infoRow(
            'Email',
            order['customer_email']?.toString() ?? '-',
          ),
          Container(height: 1, color: detailBorder),
          _infoRow(
            'Phone',
            order['customer_phone']?.toString() ?? '-',
          ),
          Container(height: 1, color: detailBorder),
          _infoRow(
            'Address',
            order['shipping_address']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: detailGold,
              size: 50,
            ),
            const SizedBox(height: 16),
            const Text(
              'UNABLE TO LOAD PRODUCTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: detailWhite,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: detailMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadItems();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: detailGold,
                foregroundColor: detailBlack,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final total = _money(order['total_amount']);
    final payment = (order['payment_status'] ?? 'PENDING').toString();
    final status = (order['status'] ?? 'PENDING').toString();

    return Scaffold(
      backgroundColor: detailBlack,
      appBar: AppBar(
        backgroundColor: detailBlack,
        foregroundColor: detailWhite,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: detailWhite,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: detailBorder),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: detailGold),
            )
          : _error != null
              ? _buildErrorState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                  children: [
                    const Text(
                      'YOUR PURCHASE',
                      style: TextStyle(
                        color: detailGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Order overview',
                      style: TextStyle(
                        color: detailWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildOrderOverview(
                      order,
                      total,
                      payment,
                      status,
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      'YOUR PRODUCTS',
                      subtitle: '${_items.length} '
                          '${_items.length == 1 ? 'item' : 'items'} in this order',
                    ),

                    if (_items.isEmpty)
                      _panel(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: detailGold,
                              size: 23,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No order items found.',
                                style: TextStyle(
                                  color: detailMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._items.map(_buildProductItem),

                    const SizedBox(height: 16),

                    _sectionTitle('SHIPPING INFORMATION'),

                    _buildShippingInfo(order),

                    const SizedBox(height: 25),

                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: detailGold,
                            size: 25,
                          ),
                          SizedBox(height: 9),
                          Text(
                            'THANK YOU FOR SHOPPING WITH LUVJAM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: detailGoldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'L U V J A M',
                            style: TextStyle(
                              color: detailGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
