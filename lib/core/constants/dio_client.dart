import "package:dio/dio.dart";
import 'api_constants.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions (
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),

      headers: {
        "Content-Type" : "application/json",
      },
    ),
  );
}
