import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/quest_create_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/views/quest_create_view.dart';
import 'package:axiom/features/quests/views/quest_payment_view.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('wizard steps through all 5 steps and submits a new quest', (
    tester,
  ) async {
    Get.put<QuestRepository>(QuestRepository());
    final listController = Get.put<QuestListController>(QuestListController());
    Get.lazyPut<QuestCreateController>(() => QuestCreateController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(name: '/quest-create', page: () => const QuestCreateView()),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed('/quest-create');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    final controller = Get.find<QuestCreateController>();
    final beforeCount = listController.quests.length;

    // Step 1: title.
    expect(find.text('DÉFINIR LA QUÊTE'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Méditer 10 minutes');
    await tester.pump();

    // Step 1 -> 2.
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    expect(find.text('DURÉE'), findsOneWidget);

    // Step 2 -> 3.
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 2);
    expect(find.text('INVITER DES ALLIÉS'), findsOneWidget);

    // Select an ally, then step 3 -> 4.
    await tester.tap(find.text('Marcus Thorne'));
    await tester.pump();
    expect(controller.selectedAllyIds, contains('c1'));
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 3);
    expect(find.text('ENJEU OPTIONNEL'), findsOneWidget);

    // Step 4 -> 5 (review).
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 4);
    expect(find.text('RÉCAPITULATIF'), findsOneWidget);
    expect(find.text('Méditer 10 minutes'), findsOneWidget);

    // Submit.
    await tester.tap(find.text('LANCER LA QUÊTE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    tester.takeException();

    expect(listController.quests.length, beforeCount + 1);
    expect(
      listController.quests.any((q) => q.title == 'Méditer 10 minutes'),
      isTrue,
    );
  });

  testWidgets(
    'entering a stake routes through mobile money payment and finalizes the quest there',
    (tester) async {
      Get.put<QuestRepository>(QuestRepository());
      final listController = Get.put<QuestListController>(QuestListController());
      Get.lazyPut<QuestCreateController>(() => QuestCreateController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.dark,
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage(name: AppRoutes.home, page: () => const Scaffold()),
            GetPage(name: AppRoutes.questCreate, page: () => const QuestCreateView()),
            GetPage(name: AppRoutes.questPayment, page: () => const QuestPaymentView()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      Get.toNamed(AppRoutes.questCreate);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      tester.takeException();

      final controller = Get.find<QuestCreateController>();
      final beforeCount = listController.quests.length;
      controller.titleController.text = 'Courir 5km';
      controller.currentStep.value = QuestCreateController.stakeStepIndex;
      await tester.pump();
      expect(find.text('ENJEU OPTIONNEL'), findsOneWidget);

      // No stake entered yet: still a plain SUIVANT.
      expect(find.text('SUIVANT'), findsOneWidget);
      expect(find.text('CONTINUER VERS LE PAIEMENT'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.pump();
      expect(find.text('CONTINUER VERS LE PAIEMENT'), findsOneWidget);

      // Pick the charity distribution option.
      await tester.ensureVisible(find.text('Donner à une association'));
      await tester.pump();
      await tester.tap(find.text('Donner à une association'));
      await tester.pump();
      expect(controller.fundsDistribution.value, FundsDistribution.charity);

      await tester.tap(find.text('CONTINUER VERS LE PAIEMENT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('PAIEMENT SÉCURISÉ'), findsOneWidget);

      // Wave is the default provider; switch to Orange Money.
      expect(controller.mobileMoneyProvider.value, MobileMoneyProvider.wave);
      await tester.tap(find.text('Orange Money'));
      await tester.pump();
      expect(controller.mobileMoneyProvider.value, MobileMoneyProvider.orangeMoney);

      await tester.enterText(find.byType(TextField).first, '0700000000');
      await tester.pump();

      await tester.ensureVisible(find.textContaining('PAYER'));
      await tester.pump();
      await tester.tap(find.textContaining('PAYER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      tester.takeException();

      // Payment finalizes the quest and pops the whole wizard stack.
      expect(controller.paymentConfirmed.value, isTrue);
      expect(listController.quests.length, beforeCount + 1);
      expect(
        listController.quests.any((q) => q.title == 'Courir 5km'),
        isTrue,
      );
      expect(Get.currentRoute, AppRoutes.home);
    },
  );

  testWidgets('SUIVANT is disabled on step 1 until a title is entered', (
    tester,
  ) async {
    Get.put<QuestRepository>(QuestRepository());
    Get.put<QuestListController>(QuestListController());
    Get.lazyPut<QuestCreateController>(() => QuestCreateController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(name: '/quest-create', page: () => const QuestCreateView()),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed('/quest-create');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    final controller = Get.find<QuestCreateController>();
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 0);
  });
}
