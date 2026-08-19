import 'dart:io';

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
// - POST /recommend/from-upload → Rekomendasi AI dari foto baru
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

  /// Minta AI mencarikan padanan outfit dari foto baru (belum ada di wardrobe).
  ///
  /// Foto dikirim langsung ke AI tanpa disimpan ke wardrobe secara permanen.
  /// Backend akan mengklasifikasi kategori foto, lalu mencarikan rekomendasi
  /// pelengkap dari isi wardrobe pengguna.
  ///
  /// [imageFile]       = File gambar dari kamera/galeri
  /// [topK]            = Berapa banyak rekomendasi per kategori (default: 5)
  /// [saveToWardrobe]  = Simpan ke wardrobe? (default: false)
  ///
  /// Return: RecommendationResponseModel (format sama dengan from-wardrobe)
  Future<RecommendationResponseModel> getRecommendationsFromUpload({
    required File imageFile,
    int topK = 5,
    bool saveToWardrobe = false,
  }) async {
    try {
      String filename = imageFile.path.split(Platform.pathSeparator).last;

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      final response = await _dioClient.dio.post(
        '/recommend/from-upload',
        data: formData,
        queryParameters: {
          'top_k': topK,
          'save_to_wardrobe': saveToWardrobe,
        },
      );
      return RecommendationResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get recommendations from upload: ${e.response?.data ?? e.message}");
      }
      final detail = e.response?.data;
      String message = "Gagal mendapatkan rekomendasi dari foto.";
      if (detail is Map && detail.containsKey('detail')) {
        message = detail['detail'].toString();
      }
      throw Exception(message);
    }
  }

  /// Simpan kombinasi outfit ke backend dan otomatis tambahkan ke Favorite (Seamless Save).
  ///
  /// 1. POST /outfits -> Simpan entity OutfitRecommendation
  /// 2. POST /favorites -> Simpan Favorite link dengan notes
  ///
  /// [itemIds]                    = list ID semua item dalam outfit (termasuk anchor)
  /// [notes]                      = catatan opsional dari pengguna
  /// [overallCompatibilityScore]  = skor keserasian padu padan
  Future<void> saveOutfit({
    required List<String> itemIds,
    String? notes,
    double? overallCompatibilityScore,
  }) async {
    try {
      final Map<String, dynamic> outfitData = {
        'item_ids': itemIds,
      };
      if (overallCompatibilityScore != null) {
        outfitData['overall_compatibility_score'] = overallCompatibilityScore;
      }

      // 1. Buat record Outfit Recommendation
      final outfitResponse = await _dioClient.dio.post(
        '/outfits',
        data: outfitData,
      );
      final outfitId = outfitResponse.data['id'];

      // 2. Buat Favorite dengan notes
      final Map<String, dynamic> favoriteData = {
        'recommendation_id': outfitId,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        favoriteData['notes'] = notes.trim();
      }

      await _dioClient.dio.post(
        '/favorites',
        data: favoriteData,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to save outfit to favorites: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menyimpan outfit.");
    }
  }

  /// Ambil semua outfit favorit tersimpan pengguna dari backend.
  ///
  /// Endpoint: GET /favorites
  Future<List<SavedOutfitModel>> getSavedOutfits() async {
    try {
      final response = await _dioClient.dio.get('/favorites');
      if (response.data is List) {
        return (response.data as List)
            .map((fav) => SavedOutfitModel.fromJson(fav as Map<String, dynamic>))
            .toList();
      }
      final listData = SavedOutfitListModel.fromJson(response.data);
      return listData.outfits;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get saved outfits: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal mengambil daftar outfit tersimpan.");
    }
  }

  /// Hapus outfit tersimpan (Favorite) berdasarkan ID Favorit.
  ///
  /// Endpoint: DELETE /favorites/{favorite_id}
  Future<void> deleteSavedOutfit(String favoriteId) async {
    try {
      await _dioClient.dio.delete('/favorites/$favoriteId');
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to delete outfit: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menghapus outfit.");
    }
  }
}
