class Product {
  final String id;
  final String name;
  final double price;
  final String desc;
  final String image;
  final double discount;
  final bool promotion;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.desc,
    required this.image,
    required this.discount,
    required this.promotion,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      desc: map['desc'] ?? '',
      image: map['image'] ?? '',
      discount: map['discount']?.toDouble() ?? 0.0,
      promotion: map['promotion'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'desc': desc,
      'image': image,
      'discount': discount,
      'promotion': promotion,
    };
  }
}
