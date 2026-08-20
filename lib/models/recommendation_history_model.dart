// ─────────────────────────────────────────────
// MODEL: Recommendation History
// Merepresentasikan log interaksi pengguna dengan outfit.
// Response dari: GET /api/v1/histories
// ─────────────────────────────────────────────

import 'package:ootdmate_frontend/models/saved_outfit_model.dart';

/// Satu record history interaksi pengguna.
class RecommendationHistoryModel {
  final String id;
  final String userId;
  final String recommendationId;
  final String? interactionType;
  final String createdAt;
  final SavedOutfitModel? outfit;

  RecommendationHistoryModel({
    required this.id,
    required this.userId,
    required this.recommendationId,
    this.interactionType,
    required this.createdAt,
    this.outfit,
  });

  factory RecommendationHistoryModel.fromJson(Map<String, dynamic> json) {
    SavedOutfitModel? outfit;
    if (json['outfit'] != null) {
      // Bungkus data outfit agar compatible dengan SavedOutfitModel.fromJson
      final outfitJson = json['outfit'] as Map<String, dynamic>;
      outfit = SavedOutfitModel.fromJson({
        'id': json['recommendation_id'] ?? '',
        'outfit': outfitJson,
        'created_at': outfitJson['created_at'] ?? json['created_at'] ?? '',
      });
    }

    return RecommendationHistoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      recommendationId: json['recommendation_id'] ?? '',
      interactionType: json['interaction_type'],
      createdAt: json['created_at'] ?? '',
      outfit: outfit,
    );
  }

  /// Label ramah untuk tipe interaksi
  String get interactionLabel {
    switch (interactionType) {
      case 'saved':
        return 'Saved';
      case 'viewed':
        return 'Viewed';
      case 'applied':
        return 'Applied';
      case 'favorited':
        return 'Favorited';
      case 'ignored':
        return 'Skipped';
      default:
        return interactionType ?? 'Unknown';
    }
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

  /// Format waktu (misal: "14:30")
  String get formattedTime {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// Balikan lis dari endpoint GET /histories
class RecommendationHistoryListModel {
  final List<RecommendationHistoryModel> histories;
  final int total;

  RecommendationHistoryListModel({
    required this.histories,
    required this.total,
  });

  factory RecommendationHistoryListModel.fromJson(Map<String, dynamic> json) {
    final rawHistories = json['histories'] as List? ?? [];
    final histories = rawHistories
        .map((h) => RecommendationHistoryModel.fromJson(h))
        .toList();

    return RecommendationHistoryListModel(
      histories: histories,
      total: (json['total'] as num?)?.toInt() ?? histories.length,
    );
  }
}
