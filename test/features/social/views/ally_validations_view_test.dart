import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/social/controllers/social_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/social/views/ally_validations_view.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  Future<SocialController> pumpView(WidgetTester tester) async {
    Get.put<SocialRepository>(SocialRepository());
    final controller = Get.put<SocialController>(SocialController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: AllyValidationsView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();
    return controller;
  }

  testWidgets('renders both photo-proof and text-proof cards with their evidence', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Sophie Valand'), findsOneWidget);
    expect(find.text('PREUVE PHOTO'), findsOneWidget);
    expect(
      find.text('Photo de la séance de lecture envoyée aujourd\'hui à 21h02.'),
      findsOneWidget,
    );

    expect(find.text('Marc Lefebvre'), findsOneWidget);
    expect(find.textContaining('Session de 20 minutes complétée'), findsOneWidget);
  });

  testWidgets('APPROUVER removes the card and updates controller state', (tester) async {
    final controller = await pumpView(tester);

    expect(controller.pendingValidations.length, 2);

    await tester.tap(find.text('APPROUVER').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.pendingValidations.length, 1);
    expect(find.text('Sophie Valand'), findsNothing);
  });

  testWidgets('resolving all requests shows the empty state', (tester) async {
    final controller = await pumpView(tester);

    while (controller.pendingValidations.isNotEmpty) {
      await tester.tap(find.text('APPROUVER').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(controller.pendingValidations, isEmpty);
    expect(find.text('FIN DES VALIDATIONS URGENTES'), findsOneWidget);
  });
}
