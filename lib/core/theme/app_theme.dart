import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Assembles the "Monolith Architect" design system into a [ThemeData].
class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: AppTypography.displayLg,
      headlineMedium: AppTypography.headlineMd,
      titleLarge: AppTypography.titleLg,
      bodyMedium: AppTypography.bodyMd,
      labelMedium: AppTypography.labelMd,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.primary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLg.copyWith(color: AppColors.primary),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.structuralRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
          elevation: 0,
          textStyle: AppTypography.labelMd,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.primaryFixedDim;
            }
            return AppColors.emerald;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: AppColors.outline20),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
          textStyle: AppTypography.labelMd,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: BorderSide(color: AppColors.outlineVariant15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: BorderSide(color: AppColors.outlineVariant15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: const BorderSide(color: AppColors.emerald),
        ),
        labelStyle: TextStyle(color: AppColors.outline),
        hintStyle: TextStyle(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
    );
  }
}
