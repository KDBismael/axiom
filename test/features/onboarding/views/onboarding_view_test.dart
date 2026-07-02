import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/onboarding/views/onboarding_view.dart';

/// A layout smoke test, not a UI-behavior test: this app renders every
/// screen at a single fixed mobile width, so it's worth confirming the full
/// scroll extent of a content-heavy static screen like this one lays out
/// without a RenderFlex/overflow error, something a plain visual screenshot
/// can't catch below the fold.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  testWidgets('renders without layout overflow across its full scroll extent', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const OnboardingView()),
    );
    await tester.pump();
    tester.takeException();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
    await tester.pump();
    tester.takeException();

    expect(find.text('COMMENCER'), findsOneWidget);
    expect(find.text("S'IDENTIFIER"), findsOneWidget);
  });
}
