import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';

class FavoriteService {
  final DioClient _dioClient = DioClient();

  /// Menambahkan rekomendasi outfit ke favorit.
  Future<void> addFavorite(String recommendationId, {String? notes}) async {
    try {
      final Map<String, dynamic> data = {'recommendation_id': recommendationId};
      if (notes != null) {
        data['notes'] = notes;
      }
      
      await _dioClient.dio.post(
        '/favorites',
        data: data,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to add favorite: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menambahkan ke favorit.");
    }
  }

  /// Menghapus favorit berdasarkan ID favorit.
  Future<void> removeFavorite(String favoriteId) async {
    try {
      await _dioClient.dio.delete('/favorites/$favoriteId');
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to remove favorite: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal menghapus favorit.");
    }
  }

  /// Mengambil daftar semua favorit pengguna.
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dioClient.dio.get('/favorites');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get favorites: ${e.response?.data ?? e.message}");
      }
      throw Exception("Gagal mengambil daftar favorit.");
    }
  }
}
