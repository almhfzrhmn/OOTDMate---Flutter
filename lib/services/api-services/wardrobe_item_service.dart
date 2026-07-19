import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';

class WardrobeItemService {
  final DioClient _dioClient = DioClient();

  // GET WARDROBE ITEMS
  Future<List<WardrobeItemModel>> getWardrobeItems({
    String? name,
    String? category,
    String? color,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/wardrobe/items',

        // SEND QUERY PARAMETER (E.G : ?category='footwear')
        queryParameters: {
          'category': ?category,
          'name': ?name,
          'color': ?color,
        },
      );

      // Get Raw Data From API
      final List<dynamic> rawDataList = response.data['items'];

      // Convert Raw Data Into Model Class
      final List<WardrobeItemModel> wardrobeList = rawDataList.map((json) {
        return WardrobeItemModel.fromJson(json);
      }).toList();

      // RETURN
      return wardrobeList;
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to get wardrobe items : ${e.message}");
      }
      throw Exception("Failed get data from server");
    }
  }
}
