import 'package:flutter/material.dart';

class LuniColors {
  const LuniColors._();

  static const cyan = Color(0xFF5BE9FF);
  static const warm = Color(0xFFFFD166);
  static const rose = Color(0xFFFF6B9D);
  static const red = Color(0xFFFF5B6E);
  static const blue = Color(0xFF76B8FF);
  static const green = Color(0xFF7BE88E);
  static const purple = Color(0xFFB48CFF);
  static const orange = Color(0xFFFF9D5B);
  static const white = Color(0xFFF0F4FF);
  static const bgDark = Color(0xFF0A0E1A);
  static const bgCard = Color(0xFF141825);
  static const bgElevated = Color(0xFF1D2433);
  static const textMuted = Color(0xFF9AA7BD);
}

class LuniTheme {
  const LuniTheme._();

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: LuniColors.cyan,
      brightness: Brightness.dark,
      primary: LuniColors.cyan,
      secondary: LuniColors.warm,
      tertiary: LuniColors.rose,
      surface: LuniColors.bgCard,
      error: LuniColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LuniColors.bgDark,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: LuniColors.bgDark,
        foregroundColor: LuniColors.white,
      ),
      cardTheme: CardThemeData(
        color: LuniColors.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0x2234455F)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LuniColors.cyan,
          foregroundColor: LuniColors.bgDark,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuniColors.white,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: Color(0x334EDAF4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuniColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LuniColors.cyan),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LuniColors.bgElevated,
        selectedColor: LuniColors.cyan.withValues(alpha: 0.18),
        labelStyle: const TextStyle(color: LuniColors.white),
        side: const BorderSide(color: Color(0x2234455F)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: LuniColors.cyan,
        unselectedLabelColor: LuniColors.textMuted,
        indicatorColor: LuniColors.cyan,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ).apply(bodyColor: LuniColors.white, displayColor: LuniColors.white),
    );
  }
}
