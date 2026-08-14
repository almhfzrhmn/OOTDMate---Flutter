import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/screens/core/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ootdmate_frontend/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ootdmate_frontend/screens/misc/onboarding/onboarding_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          return MainScreen();
        } else {
          return _hasSeenOnboarding! ? const LoginScreen() : const OnboardingScreen();
        }
      },
    );
  }
}
