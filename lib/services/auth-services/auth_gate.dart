import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ootdmate_frontend/screens/auth/login_screen.dart';
import 'package:ootdmate_frontend/screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return StreamBuilder(
      // Listen to auth changes
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {

        // Loading state
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        // If user is authenticated, navigate to main screen
        if(session != null) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}