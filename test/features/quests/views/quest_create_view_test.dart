import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/quest_create_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/views/quest_create_view.dart';
import 'package:axiom/features/social/controllers/allies_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/social/models/user_search_result.dart';
import 'package:axiom/features/payments/services/payment_feature_config.dart';
import 'package:axiom/core/routes/app_routes.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  void putAlliesController() {
    final mockSocialRepository = MockSocialRepository();
    when(() => mockSocialRepository.fetchAllies()).thenAnswer((_) async => []);
    when(
      () => mockSocialRepository.fetchInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockSocialRepository.fetchAllyRequests(),
    ).thenAnswer((_) async => []);
    Get.put<AlliesController>(AlliesController(mockSocialRepository));
  }

  QuestModel createdQuest(Map<String, dynamic> payload) {
    return QuestModel(
      id: 'new-1',
      title: payload['title'] as String,
      description: payload['description'] as String? ?? '',
      creatorId: 'user-1',
      frequency: QuestFrequency.fromJson(payload['frequency'] as String),
      durationDays: payload['durationDays'] as int,
      targetPerPeriod: (payload['targetPerPeriod'] as int?) ?? 1,
      startDate: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 30)),
      gracePeriodDays: payload['gracePeriodDays'] as int,
      riskLevel: QuestRiskLevel.fromJson(payload['riskLevel'] as String),
      requiresProof: payload['requiresProof'] as bool,
      successThresholdPercent: payload['successThresholdPercent'] as int,
      hasStake: payload['hasStake'] as bool,
      stakeAmountXof: (payload['stakeAmountXof'] as num?)?.toDouble(),
      fundsDistribution: payload['fundsDistribution'] == null
          ? null
          : FundsDistribution.fromJson(payload['fundsDistribution'] as String),
      status: (payload['hasStake'] as bool)
          ? QuestStatus.pendingPayment
          : QuestStatus.active,
      progress: 0,
      streakDays: 0,
    );
  }

  testWidgets('wizard steps through all 5 steps and submits a new quest', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.createQuest(any())).thenAnswer(
      (invocation) async => createdQuest(
        invocation.positionalArguments.single as Map<String, dynamic>,
      ),
    );

    putAlliesController();
    final listController = Get.put<QuestListController>(
      QuestListController(mockRepository),
    );
    Get.lazyPut<QuestCreateController>(
      () => QuestCreateController(listController),
    );

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

    expect(find.text('Quel type de défi ?'), findsOneWidget);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    await tester.enterText(find.byType(TextField).first, 'Méditer 10 minutes');
    await tester.enterText(find.byType(TextField).at(1), 'Pour mieux dormir.');
    await tester.pump();
    expect(find.text('Durée'), findsOneWidget);
    expect(find.text('Absences tolérées'), findsOneWidget);

    await tester.ensureVisible(find.text('Objectif'));
    await tester.pump();
    await tester.tap(find.text('+').last);
    await tester.pump();
    expect(find.text('2×'), findsOneWidget);
    await tester.tap(find.text('−').last);
    await tester.pump();
    expect(find.text('1×'), findsOneWidget);

    await tester.tap(find.text('+').first);
    await tester.pump();
    expect(find.text('31'), findsOneWidget);

    // Step 3: invite allies.
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 2);
    expect(find.text('Qui sera à tes côtés ?'), findsOneWidget);
    expect(find.text('NOUVELLE QUÊTE · ÉTAPE 3/5'), findsOneWidget);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 3);
    expect(find.text('Combien tu mets en jeu ?'), findsOneWidget);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 4);
    expect(find.text("Prêt·e à t'engager ?"), findsOneWidget);
    expect(find.text('Méditer 10 minutes'), findsOneWidget);
    expect(find.text('Absences tolérées'), findsOneWidget);

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

  testWidgets('payment feature is disabled and marked as coming soon', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    putAlliesController();
    final listController = Get.put<QuestListController>(
      QuestListController(mockRepository),
    );
    Get.lazyPut<QuestCreateController>(
      () => QuestCreateController(listController),
    );

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
    controller.titleController.text = 'Courir 5km';
    controller.currentStep.value = 3;
    await tester.pump();
    expect(find.text('Combien tu mets en jeu ?'), findsOneWidget);

    expect(find.text("SI TU ÉCHOUES, L'ENJEU VA…"), findsNothing);
    expect(
      find.text('Les enjeux financiers seront bientôt disponibles.'),
      findsOneWidget,
    );
    await tester.tap(find.text('5 000'));
    await tester.pump();
    expect(controller.hasStake.value, isFalse);
  });

  testWidgets('sandbox payment configuration enables stake controls', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    putAlliesController();
    final listController = Get.put<QuestListController>(
      QuestListController(mockRepository),
    );
    Get.lazyPut<QuestCreateController>(
      () => QuestCreateController(
        listController,
        paymentConfig: const PaymentFeatureConfig(
          payInsEnabled: true,
          environment: 'sandbox',
          sandboxVerified: true,
        ),
      ),
    );

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
    Get.toNamed('/quest-create');
    await tester.pumpAndSettle();

    final controller = Get.find<QuestCreateController>();
    controller.currentStep.value = 3;
    await tester.pump();

    expect(
      find.text('Les enjeux financiers seront bientôt disponibles.'),
      findsNothing,
    );

    await tester.ensureVisible(find.text('5 000'));
    await tester.tap(find.text('5 000'));
    await tester.pump();

    expect(controller.hasStake.value, isTrue);
    expect(find.text("SI TU ÉCHOUES, L'ENJEU VA…"), findsOneWidget);
    expect(find.text('XOF'), findsOneWidget);
  });

  testWidgets(
    'submitting a staked quest navigates to the payment screen for the new quest',
    (tester) async {
      final mockRepository = MockQuestRepository();
      when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchMyAllyInvitations(),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchMyOwnerInvitations(),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchMyGroupInvitations(),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchMyPauseRequests(),
      ).thenAnswer((_) async => []);
      when(() => mockRepository.createQuest(any())).thenAnswer(
        (invocation) async => createdQuest(
          invocation.positionalArguments.single as Map<String, dynamic>,
        ),
      );
      putAlliesController();
      final listController = Get.put<QuestListController>(
        QuestListController(mockRepository),
      );
      Get.lazyPut<QuestCreateController>(
        () => QuestCreateController(
          listController,
          paymentConfig: const PaymentFeatureConfig(
            payInsEnabled: true,
            environment: 'sandbox',
            sandboxVerified: true,
          ),
        ),
      );

      String? capturedArguments;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.dark,
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(name: '/quest-create', page: () => const QuestCreateView()),
            GetPage(
              name: AppRoutes.questPayment,
              page: () {
                capturedArguments = Get.arguments as String?;
                return const Scaffold();
              },
            ),
          ],
        ),
      );
      Get.toNamed('/quest-create');
      await tester.pumpAndSettle();

      final controller = Get.find<QuestCreateController>();
      controller.titleController.text = 'Courir 5km';
      controller.descriptionController.text = 'Pour rester en forme.';
      controller.currentStep.value = 3;
      await tester.pump();
      await tester.ensureVisible(find.text('5 000'));
      await tester.tap(find.text('5 000'));
      await tester.pump();
      controller.stakeController.text = '5000';
      controller.currentStep.value = 4;
      await tester.pump();

      await tester.tap(find.text('PAYER 5 300 XOF'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.questPayment);
      expect(capturedArguments, 'new-1');
    },
  );

  testWidgets('details require both title and description to continue', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    putAlliesController();
    final listController = Get.put<QuestListController>(
      QuestListController(mockRepository),
    );
    Get.lazyPut<QuestCreateController>(
      () => QuestCreateController(listController),
    );

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
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    await tester.enterText(find.byType(TextField).first, 'Courir');
    await tester.enterText(find.byType(TextField).at(1), '   ');
    await tester.pump();
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    await tester.enterText(find.byType(TextField).at(1), 'Pour ma santé.');
    await tester.pump();
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(controller.currentStep.value, 2);
  });

  testWidgets('searches and selects a non-ally for the quest', (tester) async {
    final questRepository = MockQuestRepository();
    when(() => questRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    final socialRepository = MockSocialRepository();
    when(() => socialRepository.fetchAllies()).thenAnswer((_) async => []);
    when(() => socialRepository.fetchInvitations()).thenAnswer((_) async => []);
    when(
      () => socialRepository.fetchAllyRequests(),
    ).thenAnswer((_) async => []);
    when(() => socialRepository.searchUsers('Awa')).thenAnswer(
      (_) async => const [
        UserSearchResult(id: 'user-2', firstName: 'Awa', lastName: 'Koné'),
      ],
    );

    Get.put<AlliesController>(AlliesController(socialRepository));
    final listController = Get.put<QuestListController>(
      QuestListController(questRepository),
    );
    final createController = Get.put<QuestCreateController>(
      QuestCreateController(listController),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const QuestCreateView()),
    );
    createController.titleController.text = 'Courir';
    createController.descriptionController.text = 'Pour progresser.';
    createController.currentStep.value = 2;
    await tester.pump();

    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'Awa');
    await tester.pumpAndSettle();

    verify(() => socialRepository.searchUsers('Awa')).called(1);
    expect(Get.find<AlliesController>().searchResults.single.id, 'user-2');
    expect(Get.find<AlliesController>().searchQuery.value, 'Awa');
    expect(Get.find<AlliesController>().allies, isEmpty);

    expect(find.text('AUTRES MEMBRES', skipOffstage: false), findsOneWidget);
    expect(find.text('Awa Koné', skipOffstage: false), findsOneWidget);
    await tester.ensureVisible(find.text('Awa Koné', skipOffstage: false));
    await tester.tap(find.text('Awa Koné', skipOffstage: false));
    await tester.pump();
    expect(createController.selectedAllyIds, contains('user-2'));
    expect(find.text('SÉLECTIONNÉS · 1'), findsOneWidget);
    await tester.tap(find.text('←'));
    await tester.pump();
    expect(createController.currentStep.value, 1);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(find.text('Awa Koné'), findsOneWidget);
  });

  testWidgets('sponsoring requires selecting a recipient in the details step', (
    tester,
  ) async {
    final questRepository = MockQuestRepository();
    when(() => questRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    when(() => questRepository.createQuest(any())).thenAnswer(
      (invocation) async => createdQuest(
        invocation.positionalArguments.single as Map<String, dynamic>,
      ),
    );
    final socialRepository = MockSocialRepository();
    when(() => socialRepository.fetchAllies()).thenAnswer((_) async => []);
    when(() => socialRepository.fetchInvitations()).thenAnswer((_) async => []);
    when(
      () => socialRepository.fetchAllyRequests(),
    ).thenAnswer((_) async => []);
    when(() => socialRepository.searchUsers('Awa')).thenAnswer(
      (_) async => const [
        UserSearchResult(id: 'user-2', firstName: 'Awa', lastName: 'Koné'),
      ],
    );

    Get.put<AlliesController>(AlliesController(socialRepository));
    final listController = Get.put<QuestListController>(
      QuestListController(questRepository),
    );
    final createController = Get.put<QuestCreateController>(
      QuestCreateController(listController),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const QuestCreateView()),
    );

    await tester.tap(find.text('Parrainer'));
    await tester.pump();
    expect(createController.createForSomeoneElse.value, isTrue);
    expect(createController.stepCount, 5);
    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(createController.currentStep.value, 1);
    await tester.enterText(find.byType(TextField).first, 'Cadeau sport');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Pour relever un défi.',
    );
    await tester.pump();
    expect(find.text('DESTINATAIRE'), findsOneWidget);

    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(createController.currentStep.value, 1);

    await tester.ensureVisible(find.text('Choisir un destinataire'));
    await tester.tap(find.text('Choisir un destinataire'));
    await tester.pumpAndSettle();
    expect(find.text('Rechercher un destinataire'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller == createController.inviteeSearchController,
      ),
      'Awa',
    );
    await tester.pumpAndSettle();
    expect(find.text('Awa Koné'), findsOneWidget);
    final keyboardTop =
        tester.view.physicalSize.height / tester.view.devicePixelRatio - 220;
    expect(
      tester.getBottomLeft(find.text('Awa Koné')).dy,
      lessThan(keyboardTop),
    );
    await tester.tap(find.text('Awa Koné'));
    await tester.pumpAndSettle();
    expect(createController.selectedInviteeId.value, 'user-2');
    expect(find.text('Awa Koné'), findsOneWidget);
    tester.view.resetViewInsets();

    await tester.tap(find.text('CONTINUER'));
    await tester.pump();
    expect(createController.currentStep.value, 2);
    expect(find.text('Qui sera à tes côtés ?'), findsOneWidget);
  });
}
