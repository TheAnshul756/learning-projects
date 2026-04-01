import 'package:flutter/material.dart';

const _red = Color(0xFFFF0000);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _red,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F0F0F),
    surfaceContainerHighest: const Color(0xFF272727),
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  cardTheme: const CardThemeData(
    color: Color(0xFF1A1A1A),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F0F0F),
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF272727),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(color: Color(0xFFAAAAAA)),
    bodySmall: TextStyle(color: Color(0xFF888888)),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF3D3D3D),
    thickness: 1,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: _red),
);

const kCardBg = Color(0xFF1A1A1A);
const kSurface = Color(0xFF272727);
const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFFAAAAAA);
const kAccent = _red;
