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

  void _loadTheme() async {
    final box = await Hive.openBox(_themeBox);
    _isDarkMode = box.get('isDarkMode', defaultValue: false);
    AppTheme.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    AppTheme.setDarkMode(_isDarkMode);
    final box = await Hive.openBox(_themeBox);
    await box.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}