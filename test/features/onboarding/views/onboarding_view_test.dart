import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/onboarding/controllers/onboarding_controller.dart';
import 'package:axiom/features/onboarding/views/onboarding_view.dart';

/// A layout smoke test, not a UI-behavior test: confirms the 3-slide intro
/// renders without overflow and that "SUIVANT" advances the visible slide.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  testWidgets('renders the first slide and advances on SUIVANT', (
    tester,
  ) async {
    Get.put(OnboardingController());
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const OnboardingView()),
    );
    await tester.pump();
    tester.takeException();

    expect(find.text('DES HABITUDES QUI TIENNENT'), findsOneWidget);
    expect(find.text('SUIVANT'), findsOneWidget);

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.text('ENGAGEZ VOTRE ARGENT'), findsOneWidget);
  });

  testWidgets('shows COMMENCER on the last slide', (tester) async {
    final controller = Get.put(OnboardingController());
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const OnboardingView()),
    );
    await tester.pump();

    controller.currentPage.value = OnboardingController.slideCount - 1;
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.text('COMMENCER'), findsOneWidget);
    expect(find.text('SUIVANT'), findsNothing);
  });
}
