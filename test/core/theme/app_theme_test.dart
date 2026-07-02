import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_colors.dart';
import 'package:axiom/core/theme/app_radii.dart';
import 'package:axiom/core/theme/app_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpTheme(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const Scaffold()),
    );
    tester.takeException();
  }

  group('AppTheme.dark', () {
    testWidgets('uses AppColors.surface as scaffold background', (tester) async {
      await pumpTheme(tester);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.surface);
    });

    testWidgets('colorScheme.primary matches AppColors.primary', (tester) async {
      await pumpTheme(tester);
      expect(AppTheme.dark.colorScheme.primary, AppColors.primary);
    });

    testWidgets('elevated and outlined button themes use interactive radius', (
      tester,
    ) async {
      await pumpTheme(tester);
      final elevatedShape = AppTheme.dark.elevatedButtonTheme.style
          ?.shape
          ?.resolve(<WidgetState>{}) as RoundedRectangleBorder?;
      final outlinedShape = AppTheme.dark.outlinedButtonTheme.style
          ?.shape
          ?.resolve(<WidgetState>{}) as RoundedRectangleBorder?;
      expect(
        (elevatedShape?.borderRadius as BorderRadius?)?.topLeft.x,
        AppRadii.interactive,
      );
      expect(
        (outlinedShape?.borderRadius as BorderRadius?)?.topLeft.x,
        AppRadii.interactive,
      );
    });

    testWidgets('has no default elevation (No-Line rule)', (tester) async {
      await pumpTheme(tester);
      expect(AppTheme.dark.appBarTheme.elevation, 0);
      expect(AppTheme.dark.cardTheme.elevation, 0);
    });

    testWidgets('textTheme is built on Inter', (tester) async {
      await pumpTheme(tester);
      expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, contains('Inter'));
    });
  });
}
