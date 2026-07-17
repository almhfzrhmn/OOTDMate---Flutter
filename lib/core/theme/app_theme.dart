import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // COLOR PALETTE
  // ─────────────────────────────────────────────

  // CORE
  static const Color primary = Color(0xFF0C0C0C);
  static const Color primarySecond = Color(0xFF0D0D0D);
  static const Color secondary = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color mediumGrey =  Color(0xFF4D4D4D);
  static const Color lightGrey = Color(0xFFA0A0A0);
  
  // ACCENT COLORS
  static const Color neonBlue = Color(0xFF00F0FF);
  static const Color acidGreen = Color(0xFFCCFF00);
  static const Color glitchMagenta = Color(0xFFFF007A);
  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFF8C8C8C);

  // STATE COLORS
  static const Color error = Color(0xFFEA2115);
  static const Color success = Color(0xFF00E676);

  // ─────────────────────────────────────────────
  // THEME DATA
  // ─────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: textPrimary,
      secondary: secondary,
      onSecondary: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: error,
      onError: textPrimary,
    ),
    scaffoldBackgroundColor: primary,

    // ── TEXT THEME ──
    textTheme: TextTheme(

      displayLarge: GoogleFonts.poppins(
        fontSize: 50,
        fontWeight: FontWeight.w900,                  // APP BRAND
        color: textPrimary
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        height: 1.2,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      
      titleLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),

    // ── APP BAR ──
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),

    // ── ELEVATED BUTTON ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: acidGreen,
        foregroundColor: primary,
        fixedSize: const Size(148, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary
        ),
      ),
    ),

    // ── TEXT BUTTON ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textSecondary,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── OUTLINED BUTTON ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(color: textSecondary.withAlpha(51)),
      ),
    ),

    // ── INPUT DECORATION ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey.withAlpha(153),
      hintStyle: GoogleFonts.poppins(
        color: secondary.withAlpha(150),
        fontSize: 14,
      ),
      prefixIconColor: secondary,
      suffixIconColor: secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: textSecondary.withAlpha(26)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: error,
      ),
    ),

    // ── SNACKBAR ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: acidGreen,
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: textPrimary,
      ),
    ),

    // ── CARD ──
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // ── DIVIDER ──
    dividerTheme: DividerThemeData(
      color: textSecondary.withAlpha(26),
      thickness: 1,
    ),
  );
  
}
