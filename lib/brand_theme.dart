import 'package:flutter/material.dart';

/// Design tokens based on the Familia Financas brand manual.
abstract final class BrandColors {
  static const green = Color(0xFF0F7A5A);
  static const greenBright = Color(0xFF1FA97C);
  static const mint = Color(0xFFDCF2E8);
  static const coral = Color(0xFFE2603C);
  static const coralText = Color(0xFFC24A28);
  static const gold = Color(0xFFF2B441);
  static const graphite = Color(0xFF10221C);
  static const fog = Color(0xFF6B7A74);
  static const sand = Color(0xFFF7F5EF);
  static const line = Color(0xFFE7E4DB);
}

abstract final class BrandTheme {
  static ThemeData create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? BrandColors.greenBright : BrandColors.green;
    final surface = dark ? const Color(0xFF14261F) : Colors.white;
    final background = dark ? const Color(0xFF0B1714) : BrandColors.sand;
    final text = dark ? const Color(0xFFEDF3F0) : BrandColors.graphite;
    final muted = dark ? const Color(0xFF93A49D) : BrandColors.fog;
    final border = dark ? const Color(0xFF24382F) : BrandColors.line;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF06231A) : Colors.white,
      surface: surface,
      onSurface: text,
      error: dark ? const Color(0xFFF58063) : BrandColors.coralText,
      primaryContainer: dark ? const Color(0xFF1B3D31) : BrandColors.mint,
      onPrimaryContainer: dark ? const Color(0xFFBFEFDA) : BrandColors.green,
      tertiary: BrandColors.gold,
      onTertiary: BrandColors.graphite,
      outline: border,
    );
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final textTheme = base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: text,
      displayColor: text,
    ).copyWith(
      displayLarge: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800),
      displayMedium: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800),
      headlineLarge: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800),
      headlineMedium: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800),
      titleLarge: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800),
    );

    final rounded16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: border),
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: surface,
        shape: rounded16,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: dark ? const Color(0xFF1B3D31) : BrandColors.mint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? primary : muted),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: BrandColors.gold,
        linearTrackColor: border,
        borderRadius: BorderRadius.circular(3),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF20362D) : BrandColors.graphite,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
