import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/text_size_provider.dart';

/// Утилита для адаптивного масштабирования текста в зависимости от размера экрана.
/// 
/// Использует базовую ширину экрана 375 пикселей (iPhone SE/8) как эталон.
/// Размеры шрифтов масштабируются пропорционально ширине экрана.
class ResponsiveText {
  /// Базовая ширина экрана для расчета масштаба (iPhone SE/8)
  static const double _baseWidth = 375.0;
  
  /// Минимальный коэффициент масштабирования
  static const double _minScaleFactor = 0.8;
  
  /// Максимальный коэффициент масштабирования
  static const double _maxScaleFactor = 1.3;

  /// Возвращает коэффициент масштабирования на основе ширины экрана.
  /// 
  /// [context] - BuildContext для получения размеров экрана
  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / _baseWidth;
    
    // Ограничиваем масштаб в разумных пределах
    scaleFactor = scaleFactor.clamp(_minScaleFactor, _maxScaleFactor);
    
    // Применяем пользовательский множитель размера текста, если доступен
    try {
      final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: true);
      scaleFactor *= textSizeProvider.textScaleFactor;
    } catch (e) {
      // Если провайдер недоступен, используем базовый масштаб
    }
    
    return scaleFactor;
  }

  /// Возвращает адаптивный размер шрифта.
  /// 
  /// [context] - BuildContext для получения размеров экрана
  /// [baseFontSize] - базовый размер шрифта
  static double fontSize(BuildContext context, double baseFontSize) {
    return baseFontSize * getScaleFactor(context);
  }

  /// Возвращает адаптивный размер для маленького текста (10-12sp).
  static double small(BuildContext context) {
    return fontSize(context, 11);
  }

  /// Возвращает адаптивный размер для обычного текста (14-16sp).
  static double body(BuildContext context) {
    return fontSize(context, 14);
  }

  /// Возвращает адаптивный размер для подзаголовков (16-18sp).
  static double subtitle(BuildContext context) {
    return fontSize(context, 16);
  }

  /// Возвращает адаптивный размер для заголовков (20-24sp).
  static double title(BuildContext context) {
    return fontSize(context, 22);
  }

  /// Возвращает адаптивный размер для больших заголовков (28-36sp).
  static double headline(BuildContext context) {
    return fontSize(context, 32);
  }

  /// Возвращает адаптивный размер для очень больших заголовков (36-48sp).
  static double display(BuildContext context) {
    return fontSize(context, 36);
  }
}

/// Extension для удобного использования адаптивных размеров шрифта.
extension ResponsiveTextExtension on num {
  /// Возвращает адаптивный размер шрифта.
  /// 
  /// Пример использования:
  /// ```dart
  /// Text('Hello', style: TextStyle(fontSize: 16.sp(context)))
  /// ```
  double sp(BuildContext context) {
    return ResponsiveText.fontSize(context, toDouble());
  }
}
