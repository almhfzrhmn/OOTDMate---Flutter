import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/models/wardrobe_stats_model.dart';

class WardrobeItemService {
  final DioClient _dioClient = DioClient();

  // ──────────────────────────────────────────────
  // GET WARDROBE ITEMS (Paginated)
  // ──────────────────────────────────────────────
  Future<List<WardrobeItemModel>> getWardrobeItems({
    String? name,
    String? category,
    String? color,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/wardrobe/items',
        queryParameters: {
          'category': category,
          'name': name,
          'color': color,
          'page': page,
          'limit': limit,
        },
      );

      // Get Raw Data From API
      final List<dynamic> rawDataList = response.data['items'];

      // Convert Raw Data Into Model Class
      final List<WardrobeItemModel> wardrobeList = rawDataList.map((json) {
        return WardrobeItemModel.fromJson(json);
      }).toList();

      return wardrobeList;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get wardrobe items : ${e.message}");
      }
      throw Exception("Failed get data from server");
    }
  }

  Future<Map<String, dynamic>> classifyWardrobeItem({
    required File imageFile,
  }) async {
    try {
      String filename = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      final response = await _dioClient.dio.post(
        '/wardrobe/classify',
        data: formData,
      );

      return {
        'category': response.data['category'] as String,
        'category_confidence': (response.data['category_confidence'] as num).toDouble(),
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to classify image: ${e.response?.data ?? e.message}");
      }
      throw Exception(e.response?.data['detail'] ?? "Gagal menganalisis gambar pakaian");
    }
  }

  Future<WardrobeItemModel> uploadWardrobeItems({
    required File imageFile,
    String? name,
    String? brand,
    String? color,
    String? notes,
  }) async {
    try {
      // Take filename from path
      String filename = imageFile.path.split('/').last;

      // Wrap into multi-form data
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
        if (name != null && name.isNotEmpty) 'name': name,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (color != null && color.isNotEmpty) 'color': color,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      final response = await _dioClient.dio.post(
        '/wardrobe/items',
        data: formData,
      );

      // Convert response from server to model
      return WardrobeItemModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to upload wardrobe item : ${e.response?.data ?? e.message}");
      }
      throw Exception(e.response?.data['detail'] ?? "Failed to upload image to server");
    }
  }

  // ──────────────────────────────────────────────
  // UPDATE WARDROBE ITEM METADATA (Step 2: Name, Brand, Color, Notes)
  // After ML classification, user can fill in metadata and save.
  // Calls PUT /wardrobe/items/{itemId} on the backend.
  // ──────────────────────────────────────────────
  Future<WardrobeItemModel> updateWardrobeItem({
    required String itemId,
    String? name,
    String? brand,
    String? color,
    String? notes,
  }) async {
    try {
      // Build update payload — only include non-null fields
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (brand != null) updateData['brand'] = brand;
      if (color != null) updateData['color'] = color;
      if (notes != null) updateData['notes'] = notes;

      final response = await _dioClient.dio.put(
        '/wardrobe/items/$itemId',
        data: updateData,
      );

      return WardrobeItemModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to update wardrobe item : ${e.response?.data ?? e.message}");
      }
      throw Exception(e.response?.data['detail'] ?? "Failed to update item metadata");
    }
  }

  // ──────────────────────────────────────────────
  // DELETE WARDROBE ITEM
  // ──────────────────────────────────────────────
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      await _dioClient.dio.delete('/wardrobe/items/$itemId');
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to delete wardrobe item : ${e.response?.data ?? e.message}");
      }
      throw Exception(e.response?.data['detail'] ?? "Failed to delete item");
    }
  }

  // ──────────────────────────────────────────────
  // GET WARDROBE STATS (Total items + Category breakdown)
  // Calls GET /wardrobe/stats on the backend.
  // ──────────────────────────────────────────────
  Future<WardrobeStatsModel> getWardrobeStats() async {
    try {
      final response = await _dioClient.dio.get('/wardrobe/stats');
      return WardrobeStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get wardrobe stats : ${e.response?.data ?? e.message}");
      }
      throw Exception("Failed to load wardrobe statistics");
    }
  }
}
