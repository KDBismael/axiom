import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('surface tiers match spec', () {
      expect(AppColors.surface, const Color(0xFF0B0B0D));
      expect(AppColors.surfaceContainerLowest, const Color(0xFF0F0F12));
      expect(AppColors.surfaceContainerLow, const Color(0xFF141417));
      expect(AppColors.surfaceContainer, const Color(0xFF17171B));
      expect(AppColors.surfaceContainerHigh, const Color(0xFF1B1B20));
      expect(AppColors.surfaceContainerHighest, const Color(0xFF24242A));
      expect(AppColors.surfaceBright, const Color(0xFF2C2C33));
    });

    test('text/foreground tokens match spec', () {
      expect(AppColors.primary, const Color(0xFFF4F4F1));
      expect(AppColors.onPrimary, const Color(0xFF0B0B0D));
      expect(AppColors.outline, const Color(0xFFA6A6AE));
      expect(AppColors.outlineMuted, const Color(0xFF8E8E97));
      expect(AppColors.outlineVariant, const Color(0xFF26262C));
      expect(AppColors.outlineVariantStrong, const Color(0xFF2C2C33));
    });

    test('volt accent tokens match spec', () {
      expect(AppColors.volt, const Color(0xFFC8F550));
      expect(AppColors.voltShadow, const Color(0xFF6E8F1C));
    });

    test('error tokens match spec', () {
      expect(AppColors.error, const Color(0xFFFF5C5C));
      expect(AppColors.errorSoft, const Color(0xFFFF8A8A));
      expect(AppColors.errorShadow, const Color(0xFF8A2A2A));
    });

    test('secondary accent families match spec', () {
      expect(AppColors.ember, const Color(0xFFFF7A3D));
      expect(AppColors.violet, const Color(0xFF8B7CFF));
      expect(AppColors.waveCyan, const Color(0xFF1DC8F2));
      expect(AppColors.gold, const Color(0xFFF6DC8A));
      expect(AppColors.amber, const Color(0xFFF6C85A));
    });

    test('opacity helpers resolve to expected alpha', () {
      expect(AppColors.outlineVariant15.a, closeTo(0.15, 0.01));
      expect(AppColors.outline20.a, closeTo(0.20, 0.01));
      expect(AppColors.ambientVoidShadow.a, closeTo(0.40, 0.01));
      expect(AppColors.voltTint().a, closeTo(0.08, 0.01));
      expect(AppColors.voltTint(0.1).a, closeTo(0.10, 0.01));
    });
  });
}
