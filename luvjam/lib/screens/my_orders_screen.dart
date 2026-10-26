import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_details_screen.dart';

const Color ordersBlack = Color(0xFF101010);
const Color ordersCard = Color(0xFF191919);
const Color ordersGold = Color(0xFFD6B875);
const Color ordersGoldLight = Color(0xFFF0DDA5);
const Color ordersWhite = Color(0xFFF7F5EF);
const Color ordersMuted = Color(0xFFAAA69B);
const Color ordersBorder = Color(0xFF34312A);

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please log in to view your orders.');
      }

      final result = await supabase
          .from('orders')
          .select(
            'id, created_at, total_amount, status, payment_status, '
            'customer_name, customer_email, customer_phone, shipping_address',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load orders. Please try again.';
        _loading = false;
      });

      debugPrint('LuvJam My Orders error: $e');
    }
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
        return ordersGold;
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

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Date unavailable';

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    return amount.toStringAsFixed(2);
  }

  Future<void> _openOrderDetails(
    Map<String, dynamic> order,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      ),
    );
  }

  Widget _statusChip(String label, String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
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
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$label: ${status.toUpperCase()}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: ordersGold,
      backgroundColor: ordersCard,
      onRefresh: _loadOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 110),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ordersCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: ordersGold.withAlpha(100),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: ordersGold,
            ),
          ),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              'NO ORDERS YET',
              style: TextStyle(
                color: ordersWhite,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your LuvJam purchases will appear here. '
            'Once you place an order, you can track its status here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ordersMuted,
              fontSize: 13,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'L U V J A M',
              style: TextStyle(
                color: ordersGold,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: ordersGold,
              size: 52,
            ),
            const SizedBox(height: 18),
            const Text(
              'UNABLE TO LOAD ORDERS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ordersWhite,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ordersMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ordersGold,
                foregroundColor: ordersBlack,
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'];
    final payment = (order['payment_status'] ?? 'PENDING').toString();
    final status = (order['status'] ?? 'PENDING').toString();
    final total = _formatAmount(order['total_amount']);
    final date = _formatDate(order['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ordersCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ordersBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(17),
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
                        color: ordersGold,
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
                              color: ordersMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '#$id',
                            style: const TextStyle(
                              color: ordersWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: ordersGold,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(height: 1, color: ordersBorder),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: ordersMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: ordersMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                const Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    color: ordersMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₱$total',
                  style: const TextStyle(
                    color: ordersGoldLight,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('PAYMENT', payment),
                    _statusChip('ORDER', status),
                  ],
                ),
                const SizedBox(height: 17),
                Container(height: 1, color: ordersBorder),
                const SizedBox(height: 13),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'VIEW ORDER DETAILS',
                      style: TextStyle(
                        color: ordersGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(
                      Icons.arrow_forward,
                      color: ordersGold,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ordersBlack,
      appBar: AppBar(
        backgroundColor: ordersBlack,
        foregroundColor: ordersWhite,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Orders',
              style: TextStyle(
                color: ordersWhite,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'YOUR LUVJAM PURCHASES',
              style: TextStyle(
                color: ordersGold,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
            color: ordersGold,
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ordersBorder),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ordersGold),
            )
          : _error != null
              ? _buildErrorState()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: ordersGold,
                      backgroundColor: ordersCard,
                      onRefresh: _loadOrders,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'ORDER HISTORY',
                                  style: TextStyle(
                                    color: ordersGoldLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: ordersCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: ordersBorder),
                                ),
                                child: Text(
                                  '${_orders.length} '
                                  '${_orders.length == 1 ? 'ORDER' : 'ORDERS'}',
                                  style: const TextStyle(
                                    color: ordersGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 17),
                          ..._orders.map(_buildOrderCard),
                          const SizedBox(height: 5),
                          const Center(
                            child: Text(
                              'L U V J A M',
                              style: TextStyle(
                                color: ordersGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
