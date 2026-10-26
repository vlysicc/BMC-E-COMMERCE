class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> colors;
  final List<String> sizes;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.colors,
    required this.sizes,
    required this.stock,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] as String? ?? '',
      colors: List<String>.from(map['colors'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'colors': colors,
      'sizes': sizes,
      'stock': stock,
    };
  }
}
