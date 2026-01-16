import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentYellow = Color(0xFFFBC02D);
  static const Color darkGray = Color(0xFF263238);
  static const Color lightGrayBg = Color(0xFFF5F7F6);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static ThemeData theme() {
    final base =
        ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen));
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryGreen,
        secondary: accentYellow,
        surface: Colors.white,
        background: lightGrayBg,
      ),
      scaffoldBackgroundColor: lightGrayBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.bold, color: darkGray), // H1
        titleMedium: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: darkGray), // H2
        titleLarge: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.bold, color: darkGray),
        bodyMedium: GoogleFonts.inter(fontSize: 16, color: darkGray),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: darkGray),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightGrayBg,
        foregroundColor: darkGray,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: darkGray),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: darkGray.withOpacity(0.6),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryGreen,
        secondary: accentYellow,
        surface: darkSurface,
        background: darkBg,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: lightGreen,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightGreen,
          side: const BorderSide(color: lightGreen),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      useMaterial3: true,
    );
  }
}
