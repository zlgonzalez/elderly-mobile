import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Stitch Design Token
  static const Color primaryColor = Color(0xFF4C614B);
  
  // Additional palette based on 'Prepared Environment' aesthetic
  static const Color backgroundColor = Color(0xFFFAF9F6); // Warm off-white
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF2C3E2D);
  static const Color textSecondary = Color(0xFF5E6C5F);
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    
    // Newsreader for headings, Public Sans for body text
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.newsreader(
        textStyle: baseTextTheme.displayLarge,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.newsreader(
        textStyle: baseTextTheme.displayMedium,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.newsreader(
        textStyle: baseTextTheme.displaySmall,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.newsreader(
        textStyle: baseTextTheme.headlineLarge,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.newsreader(
        textStyle: baseTextTheme.headlineMedium,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.newsreader(
        textStyle: baseTextTheme.headlineSmall,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.newsreader(
        textStyle: baseTextTheme.titleLarge,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.publicSans(
        textStyle: baseTextTheme.titleMedium,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.publicSans(
        textStyle: baseTextTheme.titleSmall,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.publicSans(
        textStyle: baseTextTheme.bodyLarge,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.publicSans(
        textStyle: baseTextTheme.bodyMedium,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.publicSans(
        textStyle: baseTextTheme.bodySmall,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.publicSans(
        textStyle: baseTextTheme.labelLarge,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.publicSans(
        textStyle: baseTextTheme.labelMedium,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.publicSans(
        textStyle: baseTextTheme.labelSmall,
        color: textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor.withAlpha(204),
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.newsreader(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.publicSans(color: textSecondary),
      ),
    );
  }
}
