import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('surface tiers match spec', () {
      expect(AppColors.surface, const Color(0xFF131313));
      expect(AppColors.surfaceContainerLowest, const Color(0xFF0E0E0E));
      expect(AppColors.surfaceContainerLow, const Color(0xFF1B1B1B));
      expect(AppColors.surfaceContainerHighest, const Color(0xFF353535));
      expect(AppColors.surfaceBright, const Color(0xFF393939));
    });

    test('primary tokens match spec', () {
      expect(AppColors.primary, const Color(0xFFFFFFFF));
      expect(AppColors.onPrimary, const Color(0xFF002117));
      expect(AppColors.primaryFixed, const Color(0xFF2B6954));
      expect(AppColors.primaryFixedDim, const Color(0xFF0B513D));
      expect(AppColors.primaryContainer, const Color(0xFFA2E2C8));
      expect(AppColors.onPrimaryContainer, const Color(0xFF000000));
    });

    test('emerald and outline tokens match spec', () {
      expect(AppColors.emerald, const Color(0xFF064E3B));
      expect(AppColors.outline, const Color(0xFF919191));
      expect(AppColors.outlineVariant, const Color(0xFF474747));
    });

    test('opacity helpers resolve to expected alpha', () {
      expect(AppColors.outlineVariant15.a, closeTo(0.15, 0.01));
      expect(AppColors.outline20.a, closeTo(0.20, 0.01));
      expect(AppColors.ambientVoidShadow.a, closeTo(0.40, 0.01));
    });
  });
}
