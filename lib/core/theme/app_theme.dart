import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0C0C0C);
  static const Color secondary = Color(0xFF481E14);
  static const Color tertiary = Color(0xFF481E14);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color background = Color(0xFF0C0C0C);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color error = Color.fromARGB(255, 224, 9, 9);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    scaffoldBackgroundColor: AppTheme.background,
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        height: 1.2,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      hintStyle: GoogleFonts.poppins(
        color: textPrimary.withAlpha(128),
        fontSize: 14,
      ),
      fillColor: AppTheme.surface.withAlpha(128),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      // Input text color is set via textTheme in ThemeData
    ),
  );
}
