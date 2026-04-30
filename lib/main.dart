import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/supabase_config.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_gate.dart';
// import 'screens/splash_screen.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

final supabase = Supabase.instance.client;

Future<void>main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseKey
  );

  // TODO: Set status bar to transparent

  runApp(const OOTDMateApp());
}

class OOTDMateApp extends StatelessWidget {
  const OOTDMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OOTDMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}
