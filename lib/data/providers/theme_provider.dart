import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeBox = 'theme';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    if (Hive.isBoxOpen(_themeBox)) {
      final box = Hive.box(_themeBox);
      _isDarkMode = box.get('isDarkMode', defaultValue: false);
      AppTheme.setDarkMode(_isDarkMode);
    } else {
      Hive.openBox(_themeBox).then((box) {
        _isDarkMode = box.get('isDarkMode', defaultValue: false);
        AppTheme.setDarkMode(_isDarkMode);
        notifyListeners();
      });
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    AppTheme.setDarkMode(_isDarkMode);
    // Notify listeners immediately before writing to disk for 0ms lag
    notifyListeners();
    final box = Hive.isBoxOpen(_themeBox)
        ? Hive.box(_themeBox)
        : await Hive.openBox(_themeBox);
    await box.put('isDarkMode', _isDarkMode);
  }
}
