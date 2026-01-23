import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static Color get primaryBackground => _isDark ? darkPrimaryBackground : Color(0xFFF1F4F8);
  static Color get primaryText => _isDark ? Color(0xFFE0E0E0) : Color(0xFF282E35);
  static Color get secondaryBackground => _isDark ? darkSecondaryBackground : Color(0xFFFFFFFF);
  static Color get alternate => _isDark ? Color(0xFF404040) : Color(0xFFE0E3E7);
  static const Color info = Color(0xFF0065FF);
  static const Color warning = Color(0xFFFF9500);
  static const Color customColor1 = Color(0xFF39D2C0);
  
  static bool _isDark = false;
  static void setDarkMode(bool isDark) {
    _isDark = isDark;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.grey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        primary: Colors.black,
        secondary: Colors.grey,
        surface: Colors.white,
        onSurface: Colors.black,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: primaryBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: GoogleFonts.robotoCondensed(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        displayLarge:
            GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium:
            GoogleFonts.oswald(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: GoogleFonts.robotoCondensed(
            fontSize: 36, fontWeight: FontWeight.w700),
        headlineSmall:
            GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge:
            GoogleFonts.interTight(fontSize: 22, fontWeight: FontWeight.w400),
        bodyLarge: GoogleFonts.robotoCondensed(
            fontSize: 18, fontWeight: FontWeight.w400),
        bodyMedium:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        labelLarge:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryText,
          foregroundColor: Colors.white,
          textStyle:
              GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.grey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        primary: Colors.white,
        secondary: Colors.grey,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.robotoCondensed(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardColor: Color(0xFF2D2D2D),
      textTheme: TextTheme(
        displayLarge:
            GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.w400, color: Colors.white),
        displayMedium:
            GoogleFonts.oswald(fontSize: 45, fontWeight: FontWeight.w400, color: Colors.white),
        displaySmall: GoogleFonts.robotoCondensed(
            fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
        headlineSmall:
            GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge:
            GoogleFonts.interTight(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white),
        bodyLarge: GoogleFonts.robotoCondensed(
            fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelLarge:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle:
              GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get theme => lightTheme;

  // Dark theme colors
  static const Color darkPrimaryBackground = Color(0xFF121212);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryBackground = Color(0xFF2D2D2D);
}
