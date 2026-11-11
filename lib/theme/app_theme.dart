import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool _isDark = false;

  static void setDarkMode(bool isDark) {
    _isDark = isDark;
  }

  static bool get isDark => _isDark;

  // Context-aware theme check - triggers immediate widget rebuild when theme switches!
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Context-aware dynamic colors
  static Color bg(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF101216) : const Color(0xFFF7F8FA);

  static Color secondaryBg(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF1A1D24) : Colors.white;

  static Color surface(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF222731) : const Color(0xFFEFF2F6);

  static Color text(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

  static Color subtext(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color secondaryTextCol(BuildContext context) => subtext(context);

  static Color divider(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF28303C) : const Color(0xFFE2E8F0);

  // Backward-compatible static getters (now sync with _isDark)
  static Color get primaryBackground =>
      _isDark ? const Color(0xFF101216) : const Color(0xFFF7F8FA);
  static Color get secondaryBackground =>
      _isDark ? const Color(0xFF1A1D24) : Colors.white;
  static Color get surfaceBackground =>
      _isDark ? const Color(0xFF222731) : const Color(0xFFEFF2F6);

  static Color get primaryText =>
      _isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get secondaryText =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get dividerColor =>
      _isDark ? const Color(0xFF28303C) : const Color(0xFFE2E8F0);

  // Modern Navigation Dock colors (matching user reference Image 1)
  static const Color dockBg = Color(0xFF14161C);
  static const Color dockBgLight = Color(0xFF1E222B);
  static const Color dockItemInactive = Color(0xFF71717A);
  static const Color dockActiveAmber = Color(0xFFF59E0B);
  static const Color dockPillActiveBg = Color(0xFFF59E0B);
  static const Color dockPillActiveFg = Colors.black;

  // Brand Accents
  static const Color primaryAccent = Color(0xFF3B82F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accentEmerald = Color(0xFF10B981);

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

  /// Vibrant card styling matching the visual reference (Image 1)
  /// Returns (cardBg, textPrimary, textSecondary, badgeBg)
  static (Color cardBg, Color textPrimary, Color textSecondary, Color badgeBg)
      getLessonStyle(String type, int index) {
    final lower = type.toLowerCase();
    if (lower.contains('лек')) {
      // Vibrant Sky/Cyan (Card 1 in Image 1)
      return (
        const Color(0xFF0284C7),
        Colors.white,
        const Color(0xFFE0F2FE),
        const Color(0x33FFFFFF),
      );
    } else if (lower.contains('пр') || lower.contains('сем')) {
      // Warm Vibrant Coral/Orange (Card 2 in Image 1)
      return (
        const Color(0xFFEA580C),
        Colors.white,
        const Color(0xFFFFEDD5),
        const Color(0x33FFFFFF),
      );
    } else if (lower.contains('лаб') || lower.contains('лр')) {
      // Vibrant Violet/Purple (Card 3 in Image 1)
      return (
        const Color(0xFF7E22CE),
        Colors.white,
        const Color(0xFFF3E8FF),
        const Color(0x33FFFFFF),
      );
    } else if (lower.contains('экз') || lower.contains('зач')) {
      // Crimson / Rose
      return (
        const Color(0xFFDC2626),
        Colors.white,
        const Color(0xFFFEE2E2),
        const Color(0x33FFFFFF),
      );
    }

    // Default styles alternating by index
    if (index % 3 == 0) {
      return (
        const Color(0xFF0D9488), // Teal
        Colors.white,
        const Color(0xFFCCFBF1),
        const Color(0x33FFFFFF),
      );
    } else if (index % 3 == 1) {
      return (
        const Color(0xFFD97706), // Amber
        Colors.white,
        const Color(0xFFFEF3C7),
        const Color(0x33FFFFFF),
      );
    } else {
      return (
        const Color(0xFF4F46E5), // Indigo
        Colors.white,
        const Color(0xFFE0E7FF),
        const Color(0x33FFFFFF),
      );
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        primary: primaryAccent,
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF101216),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        primary: accentAmber,
        surface: const Color(0xFF1A1D24),
        onSurface: const Color(0xFFF1F5F9),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1D24),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1D24),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF28303C), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1D24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
