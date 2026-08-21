import 'package:flutter/foundation.dart';

/// Service singleton untuk sinkronisasi state data pakaian (wardrobe) 
/// di seluruh aplikasi (WardrobeScreen, RecommendationScreen, HomeScreen, dll).
class WardrobeSyncService {
  static final WardrobeSyncService _instance = WardrobeSyncService._internal();
  factory WardrobeSyncService() => _instance;
  WardrobeSyncService._internal();

  /// ValueNotifier yang nilainya di-increment setiap kali ada item
  /// yang ditambah, diedit, atau dihapus.
  final ValueNotifier<int> wardrobeUpdateNotifier = ValueNotifier<int>(0);

  /// Panggil fungsi ini setiap kali ada perubahan data pakaian di lemari
  void notifyWardrobeUpdated() {
    wardrobeUpdateNotifier.value++;
  }
}
