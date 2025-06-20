import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: const Color(0xFFD32F2F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),      // Rojo institucional
          secondary: const Color(0xFFFFEB3B),   // Amarillo institucional
          background: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF5722),   // Naranja fuego
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 4,
          margin: EdgeInsets.all(8),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      );
}