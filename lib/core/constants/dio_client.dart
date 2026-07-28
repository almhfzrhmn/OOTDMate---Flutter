import "package:dio/dio.dart";
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 50),
        receiveTimeout: const Duration(seconds: 50),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final session = Supabase.instance.client.auth.currentSession;
          final token = session?.accessToken;

          if(token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if(kDebugMode) {
            print("Error API : ${e.response?.statusCode} - ${e.message}");
            return handler.next(e);
          }
        },
      ),
    );
  }
}