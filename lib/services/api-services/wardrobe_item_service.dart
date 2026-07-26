import 'dart:convert';
import 'dart:io';
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


  // UPLOAD WARDROBE ITEMS
  Future<WardrobeItemModel> uploadWardrobeItems({
    required File imageFile,
    String? name,
    String? brand,
    String? color,
    String? notes,
  }) async {
    try {
    // TAKE FILENAME FROM PATH
    String filename = imageFile.path.split('/').last;

    // WRAP INTO MULTI-FORM DATA
    FormData formData = FormData.fromMap({
      'image' : await MultipartFile.fromFile(
        imageFile.path,
        filename: filename
      ),
      if (name != null && name.isNotEmpty) 'name' : name,
      if(brand != null && brand.isNotEmpty) 'brand' : brand,
      if(color != null && color.isNotEmpty) 'color' : color,
      if(notes != null && notes.isNotEmpty) 'notes' : notes
    });

    final response = await _dioClient.dio.post(
      '/wardrobe/items',
      data: formData
    );

    // CONVERT RESPONSE FROM SERVER TO MODEL
    return WardrobeItemModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Failed to upload wardrobe item : ${e.response?.data ?? e.message}");
      }
      throw Exception(e.response?.data['detail'] ?? "Failed to upload image to server");
    }
  }
}
