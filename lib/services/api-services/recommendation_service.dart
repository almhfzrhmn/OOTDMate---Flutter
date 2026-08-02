import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';
import 'package:ootdmate_frontend/models/recommendation_model.dart';

import 'package:ootdmate_frontend/models/saved_outfit_model.dart';

// ─────────────────────────────────────────────
// SERVICE: Recommendation & Outfits
// Menghubungkan Flutter dengan endpoint AI & Outfit di backend.
//
// Endpoint yang dipakai:
// - POST /recommend/from-wardrobe/{item_id}?top_k=5 → Rekomendasi AI
// - POST /outfits → Simpan kombinasi outfit
// - GET /outfits  → Ambil daftar outfit tersimpan
// - DELETE /outfits/{id} → Hapus outfit tersimpan
// ─────────────────────────────────────────────

class RecommendationService {
  final DioClient _dioClient = DioClient();

  /// Minta AI mencarikan padanan outfit berdasarkan 1 item acuan.
  ///
  /// [itemId] = ID pakaian yang dipilih user sebagai acuan
  /// [topK]   = Berapa banyak rekomendasi per kategori (default: 5)
  ///
  /// Return: RecommendationResponseModel berisi query_item + recommendations
  Future<RecommendationResponseModel> getRecommendations({
    required String itemId,
    int topK = 5,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/recommend/from-wardrobe/$itemId',
        queryParameters: {'top_k': topK},
      );
      return RecommendationResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get recommendations: ${e.response?.data ?? e.message}");
      }
      // Berikan pesan error yang jelas untuk ditampilkan di UI
      final detail = e.response?.data;
      String message = "Gagal mendapatkan rekomendasi dari AI.";
      if (detail is Map && detail.containsKey('detail')) {
        message = detail['detail'].toString();
      }
      throw Exception(message);
    }
  }

  /// Simpan kombinasi outfit ke backend (untuk fitur Save / Wear This).
  ///
  /// [itemIds] = list ID semua item dalam outfit (termasuk anchor)
  /// [notes]   = catatan opsional (misal: "Outfit untuk hangout")
  Future<void> saveOutfit({
    required List<String> itemIds,
    String? notes,
  }) async {
    try {
      await _dioClient.dio.post(
        '/outfits',
        data: {
          'item_ids': itemIds,
          'notes': notes,
        },
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to save outfit: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menyimpan outfit.");
    }
  }

  /// Ambil semua outfit tersimpan pengguna dari backend.
  ///
  /// Endpoint: GET /outfits
  Future<List<SavedOutfitModel>> getSavedOutfits() async {
    try {
      final response = await _dioClient.dio.get('/outfits');
      final listData = SavedOutfitListModel.fromJson(response.data);
      return listData.outfits;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get saved outfits: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal mengambil daftar outfit tersimpan.");
    }
  }

  /// Hapus outfit tersimpan berdasarkan ID.
  ///
  /// Endpoint: DELETE /outfits/{outfit_id}
  Future<void> deleteSavedOutfit(String outfitId) async {
    try {
      await _dioClient.dio.delete('/outfits/$outfitId');
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to delete outfit: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menghapus outfit.");
    }
  }
}
