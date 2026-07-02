import 'package:flutter/material.dart';

/// Color tokens for the "Monolith Architect" design system.
class AppColors {
  AppColors._();

  // Surfaces
  static const surface = Color(0xFF131313);
  static const surfaceContainerLowest = Color(0xFF0E0E0E);
  static const surfaceContainerLow = Color(0xFF1B1B1B);
  static const surfaceContainer = Color(0xFF232323);
  static const surfaceContainerHigh = Color(0xFF2C2C2C);
  static const surfaceContainerHighest = Color(0xFF353535);
  static const surfaceBright = Color(0xFF393939);

  // Primary
  static const primary = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFF002117);
  static const primaryFixed = Color(0xFF2B6954);
  static const primaryFixedDim = Color(0xFF0B513D);
  static const primaryContainer = Color(0xFFA2E2C8);
  static const onPrimaryContainer = Color(0xFF000000);

  // Engagement / success
  static const emerald = Color(0xFF064E3B);

  // Outline
  static const outline = Color(0xFF919191);
  static const outlineVariant = Color(0xFF474747);

  // Derived opacity helpers
  static Color get outlineVariant15 => outlineVariant.withValues(alpha: 0.15);
  static Color get outline20 => outline.withValues(alpha: 0.20);
  static Color get ambientVoidShadow => Colors.black.withValues(alpha: 0.40);
}
