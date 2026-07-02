import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_colors.dart';
import 'package:axiom/core/widgets/buttons/app_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    tester.takeException();
  }

  group('AppButton', () {
    testWidgets('renders its label', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: () {}),
      );
      expect(find.text('Create Quest'), findsOneWidget);
    });

    testWidgets('tapping invokes onPressed', (tester) async {
      var tapped = false;
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: () => tapped = true),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('onPressed: null disables the button', (tester) async {
      await pump(tester, const AppButton(label: 'Create Quest', onPressed: null));
      final elevated = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevated.onPressed, isNull);
    });

    testWidgets('primary variant fills with emerald', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: () {}),
      );
      final elevated = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final fill = elevated.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(fill, AppColors.emerald);
    });

    testWidgets('secondary variant is transparent with an outline border', (
      tester,
    ) async {
      await pump(
        tester,
        AppButton(
          label: 'Invite Friends',
          onPressed: () {},
          variant: AppButtonVariant.secondary,
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('lustre variant renders a gradient-decorated container', (
      tester,
    ) async {
      await pump(
        tester,
        AppButton(
          label: 'Get Started',
          onPressed: () {},
          variant: AppButtonVariant.lustre,
        ),
      );
      final inkBoxes = tester.widgetList<Ink>(find.byType(Ink));
      final hasGradient = inkBoxes.any(
        (i) => i.decoration is BoxDecoration &&
            (i.decoration as BoxDecoration).gradient != null,
      );
      expect(hasGradient, isTrue);
    });

    testWidgets('loading state shows a spinner and hides the label', (
      tester,
    ) async {
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: () {}, loading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Create Quest'), findsNothing);
    });
  });
}
