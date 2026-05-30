import 'package:flutter/material.dart';

/// Luni OS design tokens — ported from `ui_design/luni-styles.css`.
class LuniColors {
  const LuniColors._();

  // Surfaces (deepened from the old #0A0E1A) — multi-layer dark.
  static const bgVoid = Color(0xFF05070D); // behind everything / scrims
  static const bgBase = Color(0xFF090C15); // app background
  static const bg1 = Color(0xFF11151F); // card
  static const bg2 = Color(0xFF181D2B); // elevated / inputs
  static const bg3 = Color(0xFF222838); // pressed / hover

  // Hairlines (rgba(125,145,185, a)).
  static const hairline = Color(0x217D91B9); // ~.13
  static const hairline2 = Color(0x387D91B9); // ~.22

  // Text hierarchy.
  static const tx = Color(0xFFEAF0FF);
  static const txSoft = Color(0xFFC2CCE0);
  static const txMute = Color(0xFF8592AB);
  static const txFaint = Color(0xFF5C6680);

  // Brand + 9-tone emotion palette (from the robot firmware).
  static const cyan = Color(0xFF5BE9FF);
  static const warm = Color(0xFFFFD166);
  static const rose = Color(0xFFFF6B9D);
  static const red = Color(0xFFFF5B6E);
  static const blue = Color(0xFF76B8FF);
  static const green = Color(0xFF7BE88E);
  static const purple = Color(0xFFB48CFF);
  static const orange = Color(0xFFFF9D5B);

  static const primary = cyan;

  // Dark text used on top of bright (cyan) fills.
  static const onCyan = Color(0xFF04222B);

  // --- Backwards-compatible aliases (old names used across the codebase) ---
  static const white = tx;
  static const bgDark = bgBase;
  static const bgCard = bg1;
  static const bgElevated = bg2;
  static const textMuted = txMute;
}

/// Returns [color] with the given [opacity] (0..1) — mirrors the `hexA` helper.
Color hexA(Color color, double opacity) => color.withValues(alpha: opacity);

/// Spacing, radii, motion and elevation tokens.
class LuniTokens {
  const LuniTokens._();

  static const radiusS = 10.0;
  static const radius = 16.0;
  static const radiusL = 22.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  static const fontSans = 'Be Vietnam Pro';
  static const fontMono = 'Space Mono';

  // Motion.
  static const ease = Cubic(0.4, 0.0, 0.2, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const durFast = Duration(milliseconds: 120);
  static const durBase = Duration(milliseconds: 180);
  static const durScreen = Duration(milliseconds: 340);

  static const shadowSoft = [
    BoxShadow(color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 8)),
  ];
  static const shadowPop = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 60, offset: Offset(0, 20)),
  ];

  /// Cyan glow used under primary CTAs / FABs.
  static List<BoxShadow> glow(Color color, {double opacity = 0.5}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 30,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Reusable text styles matching the `.t-*` helpers in the design CSS.
class LuniTextStyles {
  const LuniTextStyles._();

  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7, // ~-.025em
    height: 1.08,
    color: LuniColors.tx,
  );
  static const h2 = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.42,
    color: LuniColors.tx,
  );
  static const h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.17,
    color: LuniColors.tx,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: LuniColors.tx,
  );
  static const sub = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: LuniColors.txMute,
  );
  static const cap = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    color: LuniColors.txMute,
  );
  static const over = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.54, // +.14em
    color: LuniColors.txFaint,
  );
  static const mono = TextStyle(
    fontFamily: LuniTokens.fontMono,
    letterSpacing: -0.2,
    color: LuniColors.txSoft,
  );
}

class LuniTheme {
  const LuniTheme._();

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: LuniColors.cyan,
      brightness: Brightness.dark,
      primary: LuniColors.cyan,
      onPrimary: LuniColors.onCyan,
      secondary: LuniColors.warm,
      tertiary: LuniColors.rose,
      surface: LuniColors.bg1,
      onSurface: LuniColors.tx,
      error: LuniColors.red,
    );

    InputBorder field(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LuniColors.bgBase,
      colorScheme: scheme,
      fontFamily: LuniTokens.fontSans,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: LuniColors.bgBase,
        foregroundColor: LuniColors.tx,
        titleTextStyle: LuniTextStyles.h3,
      ),
      cardTheme: CardThemeData(
        color: LuniColors.bg1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          side: const BorderSide(color: LuniColors.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LuniColors.cyan,
          foregroundColor: LuniColors.onCyan,
          minimumSize: const Size(48, 54),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuniTokens.radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuniColors.tx,
          minimumSize: const Size(48, 54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: const BorderSide(color: LuniColors.hairline2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuniTokens.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: LuniColors.cyan),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuniColors.bg2,
        hintStyle: const TextStyle(color: LuniColors.txFaint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: field(Colors.transparent),
        enabledBorder: field(Colors.transparent),
        focusedBorder: field(LuniColors.cyan),
        errorBorder: field(LuniColors.red),
        focusedErrorBorder: field(LuniColors.red),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LuniColors.bg2,
        selectedColor: LuniColors.cyan.withValues(alpha: 0.18),
        labelStyle: const TextStyle(color: LuniColors.tx),
        side: const BorderSide(color: LuniColors.hairline),
        shape: const StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: LuniColors.hairline,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: LuniColors.cyan,
        unselectedLabelColor: LuniColors.txMute,
        indicatorColor: LuniColors.cyan,
        dividerColor: LuniColors.hairline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? LuniColors.onCyan
              : const Color(0xFF7A85A0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? LuniColors.cyan
              : LuniColors.bg3,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: LuniColors.cyan,
        inactiveTrackColor: LuniColors.bg3,
        thumbColor: LuniColors.cyan,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LuniColors.bg1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radiusL),
          side: const BorderSide(color: LuniColors.hairline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuniColors.bg2,
        contentTextStyle: const TextStyle(color: LuniColors.tx),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LuniColors.cyan,
        foregroundColor: LuniColors.onCyan,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: LuniTextStyles.h1,
        headlineMedium: LuniTextStyles.h2,
        headlineSmall: LuniTextStyles.h2,
        titleLarge: LuniTextStyles.h3,
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: LuniTextStyles.body,
        bodyMedium: TextStyle(fontSize: 14, color: LuniColors.txSoft),
        bodySmall: LuniTextStyles.sub,
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ).apply(bodyColor: LuniColors.tx, displayColor: LuniColors.tx),
    );
  }
}
