import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color primaryNavy    = Color(0xFF1A3C5E);
  static const Color safetyTeal     = Color(0xFF0D7A8C);
  static const Color alertRed       = Color(0xFFD32F2F);
  static const Color warningAmber   = Color(0xFFF0A500);
  static const Color successGreen   = Color(0xFF2E7D32);
  static const Color offWhite       = Color(0xFFF5F7FA);
  static const Color darkText       = Color(0xFF1C2B3A);
  static const Color mutedText      = Color(0xFF607080);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get appTitle => GoogleFonts.inter(
        fontWeight: FontWeight.w900, // Black
        fontSize: 28,
        color: AppColors.primaryNavy,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: AppColors.primaryNavy,
      );

  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontWeight: FontWeight.w600, // SemiBold
        fontSize: 18,
        color: AppColors.safetyTeal,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.darkText,
      );

  static TextStyle get bodyText => GoogleFonts.inter(
        fontWeight: FontWeight.normal, // Regular
        fontSize: 14,
        color: AppColors.darkText,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.normal, // Regular
        fontSize: 12,
        color: AppColors.mutedText,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.white,
      );

  static TextStyle get emergencyText => GoogleFonts.inter(
        fontWeight: FontWeight.w900, // Black
        fontSize: 18,
        color: AppColors.alertRed,
        letterSpacing: 0.5,
      );
}

class UiConstants {
  UiConstants._();

  // Spacing Tokens
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 20.0;
}
