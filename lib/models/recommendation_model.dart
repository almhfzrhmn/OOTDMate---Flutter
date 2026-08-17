class QueryItemModel {
  final String? id;
  final String imageUrl;
  final String category;
  final double? confidence;

  QueryItemModel({
    this.id,
    required this.imageUrl,
    required this.category,
    this.confidence,
  });

  factory QueryItemModel.fromJson(Map<String, dynamic> json) {
    return QueryItemModel(
      id: json['id'],
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class RecommendedItemModel {
  final String id;
  final String imageUrl;
  final String category;
  final double similarityScore; // 0.0 - 1.0, makin tinggi makin cocok
  final int rank;               // Peringkat (1 = paling cocok)
  final String? name;

  RecommendedItemModel({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.similarityScore,
    required this.rank,
    this.name,
  });

  factory RecommendedItemModel.fromJson(Map<String, dynamic> json) {
    return RecommendedItemModel(
      id: json['id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      name: json['name'],
    );
  }

  /// Skor kecocokan sebagai persentase (e.g., 0.88 -> "88%")
  String get similarityPercent {
    return '${(similarityScore * 100).toStringAsFixed(0)}%';
  }
}

/// Response utama dari endpoint rekomendasi.
/// Berisi:
/// - queryItem: pakaian acuan yang dipilih user
/// - recommendations: map dari kategori → list rekomendasi (Top-K)
///
/// Contoh structure:
/// {
///   "query_item": { ... },
///   "recommendations": {
///     "Bottomwear": [ {item1}, {item2}, ... ],
///     "Footwear": [ {item1}, {item2}, ... ]
///   }
/// }
class RecommendationResponseModel {
  final QueryItemModel queryItem;

  /// Key = nama kategori (e.g., "Bottomwear", "Footwear")
  /// Value = list item rekomendasi, diurutkan dari rank 1 (paling cocok)
  final Map<String, List<RecommendedItemModel>> recommendations;

  RecommendationResponseModel({
    required this.queryItem,
    required this.recommendations,
  });

  factory RecommendationResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse query_item
    final queryItem = QueryItemModel.fromJson(json['query_item']);

    // Parse recommendations (Map<String, List<dynamic>>)
    final rawRecs = json['recommendations'] as Map<String, dynamic>? ?? {};
    final recommendations = <String, List<RecommendedItemModel>>{};

    rawRecs.forEach((category, itemList) {
      final items = (itemList as List)
          .map((item) => RecommendedItemModel.fromJson(item))
          .toList();
      recommendations[category] = items;
    });

    return RecommendationResponseModel(
      queryItem: queryItem,
      recommendations: recommendations,
    );
  }

  /// Daftar semua kategori yang ada di rekomendasi
  List<String> get categoryNames => recommendations.keys.toList();

  /// Apakah hasil rekomendasi kosong (tidak ada item yang cocok)
  bool get isEmpty => recommendations.values.every((list) => list.isEmpty);
}
