import 'package:flutter/material.dart';

/// Color tokens for the "Ndeli — Arène" design system.
class AppColors {
  AppColors._();

  // Surfaces
  static const surface = Color(0xFF0B0B0D);
  static const surfaceContainerLowest = Color(0xFF0F0F12);
  static const surfaceContainerLow = Color(0xFF141417);
  static const surfaceContainer = Color(0xFF17171B);
  static const surfaceContainerHigh = Color(0xFF1B1B20);
  static const surfaceContainerHighest = Color(0xFF24242A);
  static const surfaceBright = Color(0xFF2C2C33);

  // Text / foreground
  static const primary = Color(0xFFF4F4F1);
  static const onPrimary = Color(0xFF0B0B0D);
  static const outline = Color(0xFFA6A6AE);
  static const outlineMuted = Color(0xFF8E8E97);
  static const outlineFaint = Color(0xFF6E6E77);
  static const outlineVariant = Color(0xFF26262C);
  static const outlineVariantStrong = Color(0xFF2C2C33);

  static const primaryContainer = Color(0xFFE2FF8A);
  static const onPrimaryContainer = Color(0xFF14210A);

  // Volt — the arena's core accent: CTAs, focus states, active/selected.
  static const volt = Color(0xFFC8F550);
  static const voltShadow = Color(0xFF6E8F1C);

  // Ember — streaks, fire, risk indicators.
  static const ember = Color(0xFFFF7A3D);
  static const emberLight = Color(0xFFFF9A5C);
  static const emberBright = Color(0xFFFFB547);
  static const emberDeep = Color(0xFFFF5A1F);

  // Violet — allies / social accents.
  static const violet = Color(0xFF8B7CFF);

  // Wave — payment branding.
  static const waveBlue = Color(0xFF3A6BD6);
  static const waveCyan = Color(0xFF1DC8F2);

  // Gold — rank tiers (Or), diamond badges.
  static const gold = Color(0xFFF6DC8A);
  static const goldDim = Color(0xFFB8862E);

  // Rank tier diamond-badge gradients (Bronze -> Obsidienne), and the two
  // hero-card backgrounds ("RANG"/profile) that key off the same gold.
  static const bronzeLight = Color(0xFFE2A878);
  static const bronzeDark = Color(0xFF8A5530);
  static const argentLight = Color(0xFFEEF1F5);
  static const argentDark = Color(0xFF8E96A3);
  static const platineLight = Color(0xFFC8F5F2);
  static const platineDark = Color(0xFF4FA8A3);
  static const obsidienneLight = Color(0xFFB3A8FF);
  static const obsidienneDark = Color(0xFF3A2C8A);

  static const rankCardGoldBg = Color(0xFF2A2310);
  static const rankCardGoldBorder = Color(0xFF3A3118);
  static const rankTrackGold = Color(0xFF2C2616);
  static const rankCaptionGold = Color(0xFFB8A873);
  static const streakCardEmberBg = Color(0xFF2E1608);
  static const streakCardEmberBorder = Color(0xFF3F2112);
  static const streakCaptionEmber = Color(0xFFC98C6A);

  /// The gradient stops for a rank tier's diamond badge, lightest first.
  static List<Color> rankTierGradient(String tier) {
    switch (tier) {
      case 'Bronze':
        return [bronzeLight, bronzeDark];
      case 'Argent':
        return [argentLight, argentDark];
      case 'Platine':
        return [platineLight, platineDark];
      case 'Obsidienne':
        return [obsidienneLight, obsidienneDark];
      case 'Or':
      default:
        return [gold, goldDim];
    }
  }

  // Amber — pause / caution ("mode malade").
  static const amber = Color(0xFFF6C85A);
  static const amberShadow = Color(0xFF8A6A1A);

  // Errors
  static const error = Color(0xFFFF5C5C);
  static const errorSoft = Color(0xFFFF8A8A);
  static const errorShadow = Color(0xFF8A2A2A);
  static const errorBorder = Color(0xFF4A2525);

  // Derived opacity helpers
  static Color get outlineVariant15 => outlineVariant.withValues(alpha: 0.15);
  static Color get outline20 => outline.withValues(alpha: 0.20);
  static Color get ambientVoidShadow => Colors.black.withValues(alpha: 0.40);

  /// The `rgba(volt, .06–.10)` tint used for selected chip/card backgrounds
  /// (type picker, stake picker, risk picker, etc).
  static Color voltTint([double opacity = 0.08]) => volt.withValues(alpha: opacity);
}
