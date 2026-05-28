import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF103D7A);
  static const Color _secondary = Color(0xFFC79A3B);
  static const Color _error = Color(0xFFC62828);
  static const Color _surface = Color(0xFFF3F6FB);
  static const Color _onSurface = Color(0xFF142033);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _secondary,
          error: _error,
          surface: _surface,
          onSurface: _onSurface,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: _onSurface,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          color: Colors.white,
          shadowColor: _primary.withValues(alpha: 0.08),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(104, 52),
            side: BorderSide(color: _primary.withValues(alpha: 0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: _primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: _secondary.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: _primary.withValues(alpha: 0.08)),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          labelStyle: TextStyle(color: _onSurface.withValues(alpha: 0.74)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _primary.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _primary.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _secondary.withValues(alpha: 0.8), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        scaffoldBackgroundColor: _surface,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        dividerColor: _primary.withValues(alpha: 0.08),
        fontFamily: 'Georgia',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _secondary,
          brightness: Brightness.dark,
        ),
      );
}
