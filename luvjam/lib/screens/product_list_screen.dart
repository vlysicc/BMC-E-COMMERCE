import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'checkout_screen.dart';
import 'my_orders_screen.dart';

const Color blush = Color(0xFFD6B779);
const Color softPink = Color(0xFFD6B779);
const Color dark = Color(0xFF111111);
const Color cream = Color(0xFFF7F5F0);
const Color gold = Color(0xFFD6B779);
const Color cardDark = Color(0xFF1C1C1C);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> products = [];

  bool isLoading = true;
  String? loadError;

  int get cartCount => cart.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

  int get cartTotal => cart.fold<int>(
        0,
        (sum, item) =>
            sum + ((item['price'] as int) * (item['quantity'] as int)),
      );

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('products')
          .select(
            'id, name, description, price, image_url, colors, sizes, stock',
          )
          .order('id');

      final loaded = data.map<Map<String, dynamic>>((row) {
        return {
          'id': row['id'],
          'name': row['name'] as String,
          'description': row['description'] as String? ?? '',
          'price': (row['price'] as num).toInt(),
          'imageUrl': row['image_url'] as String? ?? '',
          'colors': List<String>.from(row['colors'] ?? []),
          'sizes': List<String>.from(row['sizes'] ?? []),
          'stock': (row['stock'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        products = loaded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = e.toString();
        isLoading = false;
      });

      debugPrint('LuvJam product loading error: $e');
    }
  }

  void showProductOptions(
    Map<String, dynamic> product, {
    bool buyNow = false,
  }) {
    final colors = List<String>.from(product['colors'] ?? []);
    final sizes = List<String>.from(product['sizes'] ?? []);
    final stock = product['stock'] as int;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock.')),
      );
      return;
    }

    if (colors.isEmpty || sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available colors or sizes.')),
      );
      return;
    }

    String selectedColor = colors.first;
    String selectedSize = sizes.contains('M') ? 'M' : sizes.first;
    int quantity = 1;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: gold, width: 0.8),
          ),
          title: Text(
            product['name'].toString(),
            style: const TextStyle(
              color: cream,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₱${product['price']}',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$stock pieces available',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 20),
                const Text('COLOR', style: _fieldLabel),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedColor,
                  dropdownColor: cardDark,
                  style: const TextStyle(color: cream),
                  decoration: _inputDecoration(),
                  items: colors
                      .map(
                        (color) => DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedColor = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('SIZE', style: _fieldLabel),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedSize,
                  dropdownColor: cardDark,
                  style: const TextStyle(color: cream),
                  decoration: _inputDecoration(),
                  items: sizes
                      .map(
                        (size) => DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSize = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('QUANTITY', style: _fieldLabel),
                Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setDialogState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: gold,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        color: cream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < stock
                          ? () => setDialogState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: gold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: dark,
              ),
              onPressed: () {
                final item = <String, dynamic>{
                  'id': product['id'],
                  'product_id': product['id'],
                  'name': product['name'],
                  'price': product['price'],
                  'color': selectedColor,
                  'size': selectedSize,
                  'selected_color': selectedColor,
                  'selected_size': selectedSize,
                  'quantity': quantity,
                  'stock': stock,
                };

                if (buyNow) {
                  Navigator.pop(dialogContext);

                  Navigator.push<void>(
                    this.context,
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(
                        cartItems: [item],
                      ),
                    ),
                  );
                  return;
                }

                final index = cart.indexWhere(
                  (existing) =>
                      existing['id'] == item['id'] &&
                      existing['color'] == selectedColor &&
                      existing['size'] == selectedSize,
                );

                final existingQty =
                    index >= 0 ? cart[index]['quantity'] as int : 0;

                if (existingQty + quantity > stock) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Quantity exceeds available stock.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (index >= 0) {
                    cart[index]['quantity'] = existingQty + quantity;
                  } else {
                    cart.add(item);
                  }
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Added to your bag.')),
                );
              },
              child: Text(buyNow ? 'CONTINUE TO CHECKOUT' : 'ADD TO BAG'),
            ),
          ],
        ),
      ),
    );
  }

  void showCart() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: gold, width: 0.8),
          ),
          title: const Text(
            'YOUR SHOPPING BAG',
            style: TextStyle(color: cream, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: cart.isEmpty
                ? const Text(
                    'Your bag is currently empty.',
                    style: TextStyle(color: Colors.white70),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(cart.length, (index) {
                          final item = cart[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item['name'].toString(),
                              style: const TextStyle(
                                color: cream,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['color']} · ${item['size']} · '
                              'Qty ${item['quantity']}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                setState(() => cart.removeAt(index));
                                setDialogState(() {});
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: gold,
                              ),
                            ),
                          );
                        }),
                        const Divider(color: Colors.white24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'TOTAL  ₱$cartTotal',
                            style: const TextStyle(
                              color: gold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            if (cart.isNotEmpty)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: dark,
                ),
                onPressed: () {
                  final items = cart
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();

                  Navigator.pop(dialogContext);

                  Navigator.push<void>(
                    this.context,
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(
                        cartItems: items,
                      ),
                    ),
                  );
                },
                child: const Text('CHECKOUT'),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildProductCard(Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    final imageUrl = (product['imageUrl'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.checkroom_outlined,
                                size: 48,
                                color: Colors.black38,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.checkroom_outlined,
                              size: 48,
                              color: Colors.black38,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: dark,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'LUVJAM',
                      style: TextStyle(
                        color: gold,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (stock <= 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 0),
            child: Text(
              product['name'].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: cream,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 4, 11, 0),
            child: Text(
              product['description'].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            child: Text(
              '₱${product['price']}',
              style: const TextStyle(
                color: gold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    stock > 0 ? () => showProductOptions(product) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: dark,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'ADD TO BAG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 9),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: stock > 0
                    ? () => showProductOptions(product, buyNow: true)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cream,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'BUY NOW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: cream,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LUVJAM',
              style: TextStyle(
                color: gold,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            Text(
              'PREMIUM COUPLE COLLECTION',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 8,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MyOrdersScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Shopping Bag',
            onPressed: showCart,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: gold,
              textColor: dark,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF29251D), Color(0xFF151515)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: gold.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THE SIGNATURE EDITION',
                      style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Better Together.',
                      style: TextStyle(
                        color: cream,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Matching styles. Timeless connection.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'DISCOVER THE COLLECTION  →',
                        style: TextStyle(
                          color: dark,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(width: 3, height: 26, color: gold),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE COLLECTION',
                          style: TextStyle(
                            color: cream,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Curated fits for your favorite person.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh products',
                    onPressed: loadProducts,
                    icon: const Icon(Icons.refresh, color: gold),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: gold),
              ),
            )
          else if (loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: gold,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load the collection.',
                        style: TextStyle(
                          color: cream,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: loadProducts,
                        child: const Text('TRY AGAIN'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'The collection is coming soon.',
                  style: TextStyle(color: cream),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => buildProductCard(products[index]),
                  childCount: products.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.53,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const TextStyle _fieldLabel = TextStyle(
  color: gold,
  fontSize: 11,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.5,
);

InputDecoration _inputDecoration() => InputDecoration(
      filled: true,
      fillColor: dark,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gold),
      ),
    );
