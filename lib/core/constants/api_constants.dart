import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseKey => dotenv.env['SUPABASE_KEY']!;

  static String get baseUrl => dotenv.env['BASE_URL']!;
}