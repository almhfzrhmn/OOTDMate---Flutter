import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/screens/core/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ootdmate_frontend/screens/auth/login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  }
  
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session != null) {
          // return BottomNavbar();
          // return const HomeScreen();
          return MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
