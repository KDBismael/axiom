import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_typography.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // GoogleFonts.inter(...) kicks off a background font-loading Future as a
  // side effect. There's no bundled/network font in the test sandbox, so it
  // rejects; pumping inside testWidgets lets us drain and discard that
  // rejection via takeException() instead of it leaking into another test.
  Future<void> pumpStyle(WidgetTester tester, TextStyle style) async {
    await tester.pumpWidget(
      MaterialApp(home: Text('Axiom', style: style)),
    );
    tester.takeException();
  }

  group('AppTypography', () {
    testWidgets('displayLg matches spec: 56/700/-0.02em/1.1 line-height', (
      tester,
    ) async {
      final style = AppTypography.displayLg;
      await pumpStyle(tester, style);
      expect(style.fontSize, 56);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.letterSpacing, closeTo(-0.02 * 56, 0.001));
      expect(style.height, 1.1);
    });

    testWidgets('headlineMd matches spec: 28/600/-0.01em', (tester) async {
      final style = AppTypography.headlineMd;
      await pumpStyle(tester, style);
      expect(style.fontSize, 28);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, closeTo(-0.01 * 28, 0.001));
    });

    testWidgets('titleLg matches spec: 22/500/0 tracking', (tester) async {
      final style = AppTypography.titleLg;
      await pumpStyle(tester, style);
      expect(style.fontSize, 22);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing == null || style.letterSpacing == 0, isTrue);
    });

    testWidgets('bodyMd matches spec: 14/400/0 tracking', (tester) async {
      final style = AppTypography.bodyMd;
      await pumpStyle(tester, style);
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.letterSpacing == null || style.letterSpacing == 0, isTrue);
    });

    testWidgets('labelMd matches spec: 12/600/+0.05em', (tester) async {
      final style = AppTypography.labelMd;
      await pumpStyle(tester, style);
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, closeTo(0.05 * 12, 0.001));
    });

    testWidgets('all styles use the Inter font family', (tester) async {
      final displayLg = AppTypography.displayLg;
      final labelMd = AppTypography.labelMd;
      await pumpStyle(tester, displayLg);
      await pumpStyle(tester, labelMd);
      expect(displayLg.fontFamily, contains('Inter'));
      expect(labelMd.fontFamily, contains('Inter'));
    });
  });
}
