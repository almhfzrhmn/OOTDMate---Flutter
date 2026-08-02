// ─────────────────────────────────────────────
// MODEL: Saved Outfit
// Merepresentasikan kombinasi outfit yang disimpan oleh user.
// Response dari: GET /api/v1/outfits
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

/// Kombinasi outfit lengkap yang telah disimpan pengguna.
class SavedOutfitModel {
  final String id;
  final String? occasion;
  final String? notes;
  final String createdAt;
  final List<SavedOutfitItemModel> items;

  SavedOutfitModel({
    required this.id,
    this.occasion,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory SavedOutfitModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .map((item) => SavedOutfitItemModel.fromJson(item))
        .toList();

    return SavedOutfitModel(
      id: json['id'] ?? '',
      occasion: json['occasion'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
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

/// Balikan lis dari endpoint GET /outfits
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
