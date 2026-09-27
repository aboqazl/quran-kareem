import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF0F6B58);
  static const paper = Color(0xFFF7F1E3);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFBFAF7),
      appBarTheme: const AppBarTheme(centerTitle: true),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      navigationBarTheme: const NavigationBarThemeData(height: 68),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101513),
      appBarTheme: const AppBarTheme(centerTitle: true),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      navigationBarTheme: const NavigationBarThemeData(height: 68),
    );
  }
}
