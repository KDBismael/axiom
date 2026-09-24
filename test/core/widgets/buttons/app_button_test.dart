import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_colors.dart';
import 'package:axiom/core/theme/app_effects.dart';
import 'package:axiom/core/widgets/buttons/app_button.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    tester.takeException();
  }

  AnimatedContainer pressableSurface(WidgetTester tester) => tester.widget<AnimatedContainer>(
        find.descendant(of: find.byType(AppPressable), matching: find.byType(AnimatedContainer)),
      );

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

    testWidgets('onPressed: null disables the button (tap is a no-op)', (tester) async {
      var tapped = false;
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: null),
      );
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('primary variant fills with volt', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Create Quest', onPressed: () {}),
      );
      final decoration = pressableSurface(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.volt);
    });

    testWidgets('danger variant fills with error red', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Supprimer', onPressed: () {}, variant: AppButtonVariant.danger),
      );
      final decoration = pressableSurface(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.error);
    });

    testWidgets('amber variant fills with amber', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Mettre en pause', onPressed: () {}, variant: AppButtonVariant.amber),
      );
      final decoration = pressableSurface(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.amber);
    });

    testWidgets('secondary variant is bordered and dark-filled, no drop shadow', (
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
      expect(find.byType(AppPressable), findsNothing);
      expect(find.byType(InkWell), findsOneWidget);
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

    testWidgets('icon + long label does not overflow at narrow width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: AppButton(
                label: 'Continuer avec Google',
                leadingIcon: Icons.g_mobiledata,
                onPressed: () {},
                variant: AppButtonVariant.secondary,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('primary with trailingIcon + long label does not overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: AppButton(
                label: 'CONTINUER VERS LE PAIEMENT',
                trailingIcon: Icons.arrow_forward,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
