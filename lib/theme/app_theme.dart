import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool _isDark = false;

  static void setDarkMode(bool isDark) {
    _isDark = isDark;
  }

  static bool get isDark => _isDark;

  // Background colors
  static Color get primaryBackground =>
      _isDark ? const Color(0xFF121417) : const Color(0xFFF6F8FA);
  static Color get secondaryBackground =>
      _isDark ? const Color(0xFF1E2228) : Colors.white;
  static Color get surfaceBackground =>
      _isDark ? const Color(0xFF262C34) : const Color(0xFFEFF2F6);

  // Text colors
  static Color get primaryText =>
      _isDark ? const Color(0xFFF0F4F8) : const Color(0xFF191D23);
  static Color get secondaryText =>
      _isDark ? const Color(0xFF9AA5B1) : const Color(0xFF626D7A);

  // Borders & Dividers
  static Color get dividerColor =>
      _isDark ? const Color(0xFF2B323C) : const Color(0xFFE2E7EE);

  // Brand Accent
  static const Color primaryAccent = Color(0xFF2563EB); // Royal Blue
  static const Color accentLight = Color(0xFF3B82F6);

  // Lesson Type semantic colors
  static const Color lectureBgLight = Color(0xFFE0EDFF);
  static const Color lectureFgLight = Color(0xFF1D4ED8);
  static const Color lectureBgDark = Color(0xFF1E3A8A);
  static const Color lectureFgDark = Color(0xFF93C5FD);

  static const Color practiceBgLight = Color(0xFFDCFCE7);
  static const Color practiceFgLight = Color(0xFF15803D);
  static const Color practiceBgDark = Color(0xFF14532D);
  static const Color practiceFgDark = Color(0xFF86EFAC);

  static const Color labBgLight = Color(0xFFF3E8FF);
  static const Color labFgLight = Color(0xFF7E22CE);
  static const Color labBgDark = Color(0xFF581C87);
  static const Color labFgDark = Color(0xFFD8B4FE);

  static const Color examBgLight = Color(0xFFFEE2E2);
  static const Color examFgLight = Color(0xFFB91C1C);
  static const Color examBgDark = Color(0xFF7F1D1D);
  static const Color examFgDark = Color(0xFFFCA5A5);

  static const Color otherBgLight = Color(0xFFFEF3C7);
  static const Color otherFgLight = Color(0xFFB45309);
  static const Color otherBgDark = Color(0xFF78350F);
  static const Color otherFgDark = Color(0xFFFDE68A);

  static (Color bg, Color fg) getLessonTypeColors(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('лек')) {
      return _isDark
          ? (lectureBgDark, lectureFgDark)
          : (lectureBgLight, lectureFgLight);
    } else if (lower.contains('пр') || lower.contains('сем')) {
      return _isDark
          ? (practiceBgDark, practiceFgDark)
          : (practiceBgLight, practiceFgLight);
    } else if (lower.contains('лаб') || lower.contains('лр')) {
      return _isDark ? (labBgDark, labFgDark) : (labBgLight, labFgLight);
    } else if (lower.contains('экз') || lower.contains('зач')) {
      return _isDark ? (examBgDark, examFgDark) : (examBgLight, examFgLight);
    }
    return _isDark ? (otherBgDark, otherFgDark) : (otherBgLight, otherFgLight);
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        primary: primaryAccent,
        surface: Colors.white,
        onSurface: const Color(0xFF191D23),
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF191D23)),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF191D23),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E7EE), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121417),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        primary: accentLight,
        surface: const Color(0xFF1E2228),
        onSurface: const Color(0xFFF0F4F8),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E2228),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFFF0F4F8)),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFF0F4F8),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2228),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2B323C), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E2228),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
