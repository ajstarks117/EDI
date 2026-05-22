import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: UiConstants.primary,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.all(UiConstants.spaceSM),
      ),
      colorScheme: const ColorScheme.light(
        primary: UiConstants.primary,
        secondary: UiConstants.secondary,
        error: UiConstants.emergencyRed,
        surface: Color(0xFFF8FAFC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UiConstants.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: UiConstants.spaceLG,
            vertical: UiConstants.spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusMD),
          ),
        ),
      ),
    );
  }
}
