import 'package:flutter/material.dart';

class AppTheme {
  // 브랜드 컬러
  static const Color primary = Color(0xFF725AC1);
  static const Color background = Color(0xFFF7F4FF);

  // 상태 컬러
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFE53935);
  static const Color accent = Color(0xFFFFC107);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: background,
      foregroundColor: Colors.black,
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}