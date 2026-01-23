import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class TextSizeProvider extends ChangeNotifier {
  static const String _textSizeBox = 'text_size';
  double _textScaleFactor = 1.0; // Базовый множитель (1.0 = нормальный размер)
  
  // Доступные размеры текста
  static const List<Map<String, dynamic>> textSizeOptions = [
    {'label': 'Маленький', 'value': 0.85},
    {'label': 'Обычный', 'value': 1.0},
    {'label': 'Большой', 'value': 1.15},
    {'label': 'Очень большой', 'value': 1.3},
  ];

  double get textScaleFactor => _textScaleFactor;
  String get currentSizeLabel {
    final option = textSizeOptions.firstWhere(
      (opt) => opt['value'] == _textScaleFactor,
      orElse: () => textSizeOptions[1], // По умолчанию "Обычный"
    );
    return option['label'] as String;
  }

  TextSizeProvider() {
    _loadTextSize();
  }

  void _loadTextSize() async {
    final box = await Hive.openBox(_textSizeBox);
    _textScaleFactor = box.get('textScaleFactor', defaultValue: 1.0).toDouble();
    notifyListeners();
  }

  void setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    final box = await Hive.openBox(_textSizeBox);
    await box.put('textScaleFactor', _textScaleFactor);
    notifyListeners();
  }
}

