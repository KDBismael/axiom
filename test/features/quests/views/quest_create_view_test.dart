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

    // Step 1: title.
    expect(find.text('DÉFINIR LA QUÊTE'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Méditer 10 minutes');
    await tester.pump();

    // Step 1 -> 2 (schedule & rules).
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 1);
    expect(find.text('DURÉE'), findsOneWidget);
    expect(find.text('ABSENCES TOLÉRÉES'), findsOneWidget);
    expect(find.text('6 jours sans conséquence'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('PLUS SOUPLE'), findsOneWidget);
    expect(find.text('PLUS STRICT'), findsOneWidget);
    expect(find.text('JOURS DE RATTRAPAGE APRÈS L’ÉCHÉANCE'), findsOneWidget);

    // Step 2 -> 3 (allies, optional).
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 2);
    expect(find.text('ALLIÉS DE LA QUÊTE'), findsOneWidget);

    // Step 3 -> 4 (stake, optional).
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
    expect(find.text('Absences tolérées'), findsOneWidget);
    expect(find.text('Rattrapage après échéance'), findsOneWidget);

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
    expect(find.text('ENJEU OPTIONNEL'), findsOneWidget);

    expect(find.text('DISTRIBUTION DES FONDS'), findsNothing);
    expect(
      find.text('Les enjeux financiers seront bientôt disponibles.'),
      findsOneWidget,
    );
    final stakeSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(stakeSwitch.onChanged, isNull);
  });

  testWidgets('sandbox payment configuration enables stake controls', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
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

    final stakeSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(stakeSwitch.onChanged, isNotNull);
    expect(
      find.text('Les enjeux financiers seront bientôt disponibles.'),
      findsNothing,
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(controller.hasStake.value, isTrue);
    expect(find.text('DISTRIBUTION DES FONDS'), findsOneWidget);
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
            GetPage(
              name: '/quest-create',
              page: () => const QuestCreateView(),
            ),
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
      controller.currentStep.value = 3;
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      controller.stakeController.text = '5000';
      controller.currentStep.value = 4;
      await tester.pump();

      await tester.tap(find.text('LANCER LA QUÊTE'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.questPayment);
      expect(capturedArguments, 'new-1');
    },
  );

  testWidgets('SUIVANT is disabled on step 1 until a title is entered', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
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
    await tester.tap(find.text('SUIVANT'));
    await tester.pump();
    expect(controller.currentStep.value, 0);
  });

  testWidgets('searches and selects a non-ally for the quest', (tester) async {
    final questRepository = MockQuestRepository();
    when(() => questRepository.fetchQuests()).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyAllyInvitations(),
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
    createController.currentStep.value = 2;
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.pumpAndSettle();

    verify(() => socialRepository.searchUsers('Awa')).called(1);
    expect(Get.find<AlliesController>().searchResults.single.id, 'user-2');
    expect(Get.find<AlliesController>().searchQuery.value, 'Awa');
    expect(Get.find<AlliesController>().allies, isEmpty);

    expect(find.text('AUTRES MEMBRES', skipOffstage: false), findsOneWidget);
    expect(find.text('AWA KONÉ', skipOffstage: false), findsOneWidget);
    await tester.ensureVisible(find.text('AWA KONÉ', skipOffstage: false));
    await tester.tap(find.text('AWA KONÉ', skipOffstage: false));
    await tester.pump();
    expect(createController.selectedAllyIds, contains('user-2'));
  });
}
