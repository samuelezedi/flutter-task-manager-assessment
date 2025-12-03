import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Display fonts - Bebas Neue for headings
  static TextStyle displayLarge = GoogleFonts.bebasNeue(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.bebasNeue(
    fontSize: 46,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displaySmall = GoogleFonts.bebasNeue(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // Title text - Inter
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body text - Inter
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Labels - Inter
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );
}

