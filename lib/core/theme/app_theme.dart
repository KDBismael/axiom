import 'package:flutter/material.dart';

class AppTheme {
  static const _black = Color(0xFF0A0A0A);
  static const _white = Color(0xFFF5F5F5);
  static const _accent = Color(0xFFD4AF37); // muted gold
  static const _surface = Color(0xFF141414);
  static const _card = Color(0xFF1E1E1E);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _black,
        primaryColor: _accent,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
          onPrimary: _black,
          onSurface: _white,
        ),
        cardColor: _card,
        dividerColor: Color(0xFF2A2A2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: _black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: _white),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 24),
          titleLarge: TextStyle(color: _white, fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(color: _white, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: _white, fontSize: 15),
          bodyMedium: TextStyle(color: Color(0xFF999999), fontSize: 13),
          labelLarge: TextStyle(color: _black, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _black,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.8),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _white,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _accent),
          ),
          labelStyle: const TextStyle(color: Color(0xFF666666)),
          hintStyle: const TextStyle(color: Color(0xFF444444)),
        ),
      );
}
