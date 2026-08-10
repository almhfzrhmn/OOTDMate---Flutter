import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_gate.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash : Image.asset(
        'assets/images/splash.gif',
        width : MediaQuery.of(context).size.width * 0.8,
        height : MediaQuery.of(context).size.height * 0.8,
        fit : BoxFit.cover,
      ),
      nextScreen: const AuthGate(),
      animationDuration: Duration(seconds: 4),
      backgroundColor: AppTheme.primary,
    );
  }
}