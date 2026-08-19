// ─────────────────────────────────────────────
// MODEL: Saved Outfit (Favorite)
// Merepresentasikan kombinasi outfit yang disimpan & difavoritkan oleh user.
// Response dari: GET /api/v1/favorites atau GET /api/v1/outfits
// ─────────────────────────────────────────────

import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';

/// Item individu dalam kombinasi outfit tersimpan.
class SavedOutfitItemModel {
  final String id;
  final String wardrobeItemId;
  final String category;
  final WardrobeItemModel? wardrobeItem; // Detail lengkap pakaian (gambar, nama, dll)

  SavedOutfitItemModel({
    required this.id,
    required this.wardrobeItemId,
    required this.category,
    this.wardrobeItem,
  });

  factory SavedOutfitItemModel.fromJson(Map<String, dynamic> json) {
    return SavedOutfitItemModel(
      id: json['id'] ?? '',
      wardrobeItemId: json['wardrobe_item_id'] ?? '',
      category: json['category'] ?? '',
      wardrobeItem: json['wardrobe_item'] != null
          ? WardrobeItemModel.fromJson(json['wardrobe_item'])
          : null,
    );
  }

  /// URL Gambar (dari wardrobeItem jika tersedia)
  String get imageUrl => wardrobeItem?.imageUrl ?? '';

  /// Nama Item (dari wardrobeItem jika tersedia)
  String get name => wardrobeItem?.name ?? category;
}

/// Kombinasi outfit lengkap yang telah disimpan pengguna (Favorite).
class SavedOutfitModel {
  final String id; // ID Favorit
  final String? recommendationId; // ID Outfit Recommendation di backend
  final String? notes; // Catatan personal pengguna
  final double? overallCompatibilityScore;
  final String createdAt;
  final List<SavedOutfitItemModel> items;

  SavedOutfitModel({
    required this.id,
    this.recommendationId,
    this.notes,
    this.overallCompatibilityScore,
    required this.createdAt,
    required this.items,
  });

  factory SavedOutfitModel.fromJson(Map<String, dynamic> json) {
    // Cek apakah response dari /favorites yang menyertakan relasi 'outfit'
    final outfitJson = json['outfit'] as Map<String, dynamic>?;

    final rawItems = (outfitJson != null ? outfitJson['items'] : json['items']) as List? ?? [];
    final items = rawItems
        .map((item) => SavedOutfitItemModel.fromJson(item))
        .toList();

    final score = outfitJson != null
        ? (outfitJson['overall_compatibility_score'] as num?)?.toDouble()
        : (json['overall_compatibility_score'] as num?)?.toDouble();

    return SavedOutfitModel(
      id: json['id'] ?? '',
      recommendationId: json['recommendation_id'] ?? (outfitJson != null ? outfitJson['id'] : null),
      notes: json['notes'],
      overallCompatibilityScore: score,
      createdAt: json['created_at'] ?? (outfitJson?['created_at'] ?? ''),
      items: items,
    );
  }

  /// Format tanggal ramah pengguna (misal: "2 Aug 2026")
  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }
}

/// Balikan lis dari endpoint GET /favorites atau GET /outfits
class SavedOutfitListModel {
  final List<SavedOutfitModel> outfits;
  final int total;

  SavedOutfitListModel({
    required this.outfits,
    required this.total,
  });

  factory SavedOutfitListModel.fromJson(Map<String, dynamic> json) {
    final rawOutfits = json['outfits'] as List? ?? [];
    final outfits = rawOutfits
        .map((outfit) => SavedOutfitModel.fromJson(outfit))
        .toList();

    return SavedOutfitListModel(
      outfits: outfits,
      total: (json['total'] as num?)?.toInt() ?? outfits.length,
    );
  }
}
