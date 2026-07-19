class WardrobeItemModel {
  final String id;
  final String imageUrl;
  final String category;
  final String? name;
  final String? color;
  final String? brand;

  WardrobeItemModel({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.name,
    this.color,
    this.brand
  });

  // FACTORY
  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id'],
      imageUrl: json['image_url'],
      category: json['category'],
      name: json['name'],
      color: json['color'],
      brand: json['brand'],
    );
  }
}