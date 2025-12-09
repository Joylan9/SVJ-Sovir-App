import 'package:flutter/material.dart';

// Slightly opinionated palettes to ensure text & button contrast
ThemeData lightTheme() {
  const primary = Color(0xFF4F46E5); // indigo-ish
  const onPrimary = Colors.white;
  const scaffoldBg = Color(0xFFF6F7FB);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimary,
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

ThemeData darkTheme() {
  const primary = Color(0xFF7C3AED); // brighter for dark
  final colorScheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFF0B1020),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0B1020),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111423),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}
