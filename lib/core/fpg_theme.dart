import 'package:flutter/material.dart';

class FPGDecor {
  static BoxDecoration glowCard({bool accent = false}) => BoxDecoration(
    color: FPGTheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: accent ? FPGTheme.accent.withOpacity(.28) : Colors.white.withOpacity(.06)),
    boxShadow: accent ? [BoxShadow(color: FPGTheme.accent.withOpacity(.08), blurRadius: 24, spreadRadius: 1)] : const [],
  );
}

class FPGTheme {
  static const bg = Color(0xFF07090D);
  static const surface = Color(0xFF10141B);
  static const surface2 = Color(0xFF171C25);
  static const accent = Color(0xFFB7FF3C);
  static const muted = Color(0xFF8C96A6);

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    fontFamily: 'sans-serif',
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: surface,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF0D1117),
      indicatorColor: Color(0x223CFF9A),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0x12FFFFFF), thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}
