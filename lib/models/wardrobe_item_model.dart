class WardrobeItemModel {
  final String id;
  final String imageUrl;
  final String category;
  final double? categoryConfidence;
  final String? name;
  final String? color;
  final String? brand;
  final String? notes;
  final DateTime? createdAt;

  WardrobeItemModel({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.categoryConfidence,
    this.name,
    this.color,
    this.brand,
    this.notes,
    this.createdAt,
  });

  // FACTORY — Parse from backend WardrobeItemResponse JSON
  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id'],
      imageUrl: json['image_url'],
      category: json['category'],
      categoryConfidence: (json['category_confidence'] as num?)?.toDouble(),
      name: json['name'],
      color: json['color'],
      brand: json['brand'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // TO JSON — For sending update data to backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'category': category,
      'category_confidence': categoryConfidence,
      'name': name,
      'color': color,
      'brand': brand,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // COPY WITH — For updating fields locally (e.g., after metadata edit)
  WardrobeItemModel copyWith({
    String? id,
    String? imageUrl,
    String? category,
    double? categoryConfidence,
    String? name,
    String? color,
    String? brand,
    String? notes,
    DateTime? createdAt,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      name: name ?? this.name,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Confidence sebagai persentase (e.g., 0.9854 -> "98.5%")
  String get confidencePercent {
    if (categoryConfidence == null) return '-';
    return '${(categoryConfidence! * 100).toStringAsFixed(1)}%';
  }

  @override
  String toString() =>
      'WardrobeItemModel(id: $id, category: $category, confidence: $confidencePercent)';
}