import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';
import 'package:ootdmate_frontend/models/recommendation_history_model.dart';

class HistoryService {
  final DioClient _dioClient = DioClient();

  /// Ambil semua riwayat interaksi rekomendasi pengguna.
  ///
  /// Endpoint: GET /api/v1/histories
  Future<List<RecommendationHistoryModel>> getHistories() async {
    try {
      final response = await _dioClient.dio.get('/histories');
      final listData = RecommendationHistoryListModel.fromJson(response.data);
      return listData.histories;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get histories: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal mengambil riwayat rekomendasi.");
    }
  }

  /// Log interaksi pengguna dengan rekomendasi.
  ///
  /// [recommendationId] = ID outfit recommendation
  /// [interactionType]  = "viewed", "saved", "applied", "favorited", "ignored"
  ///
  /// Endpoint: POST /api/v1/histories
  Future<void> logHistory({
    required String recommendationId,
    required String interactionType,
  }) async {
    try {
      await _dioClient.dio.post(
        '/histories',
        data: {
          'recommendation_id': recommendationId,
          'interaction_type': interactionType,
        },
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to log history: ${e.response?.data ?? e.message}");
      }
      // Jangan throw — logging history tidak boleh menghambat flow utama
    }
  }

  /// Hapus record riwayat berdasarkan ID.
  ///
  /// Endpoint: DELETE /api/v1/histories/{history_id}
  Future<void> deleteHistory(String historyId) async {
    try {
      await _dioClient.dio.delete('/histories/$historyId');
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to delete history: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menghapus riwayat.");
    }
  }
}
