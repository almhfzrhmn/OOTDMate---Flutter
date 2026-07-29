// ─────────────────────────────────────────────
// MODEL: Wardrobe Stats
// Merepresentasikan data ringkasan lemari pakaian dari backend.
// Response dari: GET /api/v1/wardrobe/stats
// ─────────────────────────────────────────────

class WardrobeStatsModel {
  /// Jumlah total seluruh item di wardrobe user
  final int totalItems;

  /// Peta kategori → jumlah item
  /// Contoh: {"T-shirt": 5, "Pants": 4, "Jacket": 3}
  final Map<String, int> categories;

  WardrobeStatsModel({
    required this.totalItems,
    required this.categories,
  });

  /// Parse dari JSON response backend
  factory WardrobeStatsModel.fromJson(Map<String, dynamic> json) {
    return WardrobeStatsModel(
      totalItems: json['total_items'] ?? 0,
      // Konversi Map<String, dynamic> → Map<String, int>
      categories: (json['categories'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toInt()))
          ?? {},
    );
  }

  /// Menghitung persentase tiap kategori (untuk chart)
  /// Contoh: {"T-shirt": 0.333, "Pants": 0.267, ...}
  Map<String, double> get categoryPercentages {
    if (totalItems == 0) return {};
    return categories.map(
      (key, value) => MapEntry(key, value / totalItems),
    );
  }

  /// Data kosong untuk fallback saat loading / error
  factory WardrobeStatsModel.empty() {
    return WardrobeStatsModel(totalItems: 0, categories: {});
  }
}
