import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_typography.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // GoogleFonts.unbounded(...) kicks off a background font-loading Future as
  // a side effect. There's no bundled/network font in the test sandbox, so
  // it rejects; pumping inside testWidgets lets us drain and discard that
  // rejection via takeException() instead of it leaking into another test.
  Future<void> pumpStyle(WidgetTester tester, TextStyle style) async {
    await tester.pumpWidget(
      MaterialApp(home: Text('Ndeli', style: style)),
    );
    tester.takeException();
  }

  group('AppTypography', () {
    testWidgets('displayLg matches spec: Unbounded 56/800/-0.02em/1.1 line-height', (
      tester,
    ) async {
      final style = AppTypography.displayLg;
      await pumpStyle(tester, style);
      expect(style.fontSize, 56);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.letterSpacing, closeTo(-0.02 * 56, 0.001));
      expect(style.height, 1.1);
      expect(style.fontFamily, contains('Unbounded'));
    });

    testWidgets('headlineMd matches spec: Unbounded 28/800/-0.01em', (tester) async {
      final style = AppTypography.headlineMd;
      await pumpStyle(tester, style);
      expect(style.fontSize, 28);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.letterSpacing, closeTo(-0.01 * 28, 0.001));
      expect(style.fontFamily, contains('Unbounded'));
    });

    testWidgets('titleLg matches spec: Unbounded 22/700', (tester) async {
      final style = AppTypography.titleLg;
      await pumpStyle(tester, style);
      expect(style.fontSize, 22);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontFamily, contains('Unbounded'));
    });

    test('bodyMd matches spec: Geist 14/400/0 tracking', () {
      final style = AppTypography.bodyMd;
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.letterSpacing == null || style.letterSpacing == 0, isTrue);
      expect(style.fontFamily, 'Geist');
    });

    test('labelMd matches spec: Geist Mono 12/600/+0.14em', () {
      final style = AppTypography.labelMd;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, closeTo(0.14 * 12, 0.001));
      expect(style.fontFamily, 'Geist Mono');
    });
  });
}
