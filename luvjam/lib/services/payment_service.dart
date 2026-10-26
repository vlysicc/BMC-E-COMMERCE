import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  PaymentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PaymentCheckoutResult> createCheckout({
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    if (_client.auth.currentUser == null) {
      throw Exception('Please sign in before placing an order.');
    }

    final response = await _client.functions.invoke(
      'create-order',
      body: {'items': items},
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid checkout response from the server.');
    }

    final checkoutUrl = data['checkout_url'] ?? data['checkoutUrl'];
    final orderId = data['order_id'] ?? data['orderId'];

    if (checkoutUrl is! String || checkoutUrl.trim().isEmpty) {
      throw Exception('The server did not return a checkout URL.');
    }

    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw Exception('The checkout URL is invalid.');
    }

    return PaymentCheckoutResult(
      checkoutUrl: uri,
      orderId: orderId?.toString(),
    );
  }
}

class PaymentCheckoutResult {
  const PaymentCheckoutResult({
    required this.checkoutUrl,
    this.orderId,
  });

  final Uri checkoutUrl;
  final String? orderId;
}
