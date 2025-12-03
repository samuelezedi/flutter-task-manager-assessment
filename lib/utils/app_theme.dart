import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  // Primary Color Palette
  static const Color primary = Color(0xFF8D52DA); // Purple - HSL: 266 62% 59%
  static const Color secondary = Color(0xFFF26B3A); // Coral-Orange - HSL: 15 90% 62%
  static const Color tertiary = Color(0xFFC8F23A); // Yellow-Green - HSL: 75 95% 65%
  static const Color accent = Color(0xFF8B52CC); // Purple - HSL: 260 60% 55%

  // Background Colors (Dark Theme)
  // Background: Deep Blue-Purple - HSL: 250 35% 8%
  static const Color background = Color(0xFF0F0E1A);
  
  // Card: Slightly lighter - HSL: 250 30% 12%
  static const Color card = Color(0xFF1A1826);
  
  // Muted: Subdued purple - HSL: 250 20% 18%
  static const Color muted = Color(0xFF2D2A3A);
  
  // Border: Dark purple - HSL: 250 20% 20%
  static const Color border = Color(0xFF332F40);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B5C3);
  static const Color textTertiary = Color(0xFF8A8795);

  // Error and Success colors (for completeness)
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
        surface: card,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onTertiary: background,
        onError: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: background,

      // Card Theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(color: textSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: textTertiary),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.labelMedium,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 4,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        labelStyle: AppTypography.labelSmall.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}

