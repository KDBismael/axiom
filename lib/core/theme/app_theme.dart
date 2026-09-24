import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Assembles the "Ndeli — Arène" design system into a [ThemeData].
class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(fontFamily: 'Geist').copyWith(
          displayLarge: AppTypography.displayLg,
          headlineMedium: AppTypography.headlineMd,
          titleLarge: AppTypography.titleLg,
          bodyMedium: AppTypography.bodyMd,
          labelMedium: AppTypography.labelMd,
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.volt,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.primary,
        error: AppColors.error,
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
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.structuralRadius,
          side: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volt,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 58),
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
              return AppColors.voltShadow;
            }
            return AppColors.volt;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 58),
          side: BorderSide(color: AppColors.outlineVariantStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
          textStyle: AppTypography.labelMd,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: BorderSide(color: AppColors.outlineVariantStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: BorderSide(color: AppColors.outlineVariantStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.interactiveRadius,
          borderSide: const BorderSide(color: AppColors.volt),
        ),
        labelStyle: TextStyle(color: AppColors.outlineMuted),
        hintStyle: TextStyle(color: AppColors.outlineFaint),
      ),
    );
  }
}
