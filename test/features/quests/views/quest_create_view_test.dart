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
    when(() => mockSocialRepository.fetchInvitations()).thenAnswer((_) async => []);
    when(() => mockSocialRepository.fetchAllyRequests()).thenAnswer((_) async => []);
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
      status: (payload['hasStake'] as bool) ? QuestStatus.pendingPayment : QuestStatus.active,
      progress: 0,
      streakDays: 0,
    );
  }

  testWidgets('wizard steps through all 5 steps and submits a new quest', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(() => mockRepository.fetchMyAllyInvitations()).thenAnswer((_) async => []);
    when(() => mockRepository.createQuest(any())).thenAnswer(
      (invocation) async => createdQuest(invocation.positionalArguments.single as Map<String, dynamic>),
    );

    putAlliesController();
    final listController = Get.put<QuestListController>(QuestListController(mockRepository));
    Get.lazyPut<QuestCreateController>(() => QuestCreateController(listController));

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

  testWidgets('enabling the stake toggle reveals the amount field and funds distribution', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(() => mockRepository.fetchMyAllyInvitations()).thenAnswer((_) async => []);
    putAlliesController();
    final listController = Get.put<QuestListController>(QuestListController(mockRepository));
    Get.lazyPut<QuestCreateController>(() => QuestCreateController(listController));

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

    // No stake yet: distribution options aren't shown.
    expect(find.text('DISTRIBUTION DES FONDS'), findsNothing);

    controller.hasStake.value = true;
    await tester.pump();
    expect(find.text('DISTRIBUTION DES FONDS'), findsOneWidget);

    await tester.ensureVisible(find.text('Donner à une association'));
    await tester.pump();
    await tester.tap(find.text('Donner à une association'));
    await tester.pump();
    expect(controller.fundsDistribution.value, FundsDistribution.charity);
  });

  testWidgets('SUIVANT is disabled on step 1 until a title is entered', (
    tester,
  ) async {
    final mockRepository = MockQuestRepository();
    when(() => mockRepository.fetchQuests()).thenAnswer((_) async => []);
    when(() => mockRepository.fetchMyAllyInvitations()).thenAnswer((_) async => []);
    final listController = Get.put<QuestListController>(QuestListController(mockRepository));
    Get.lazyPut<QuestCreateController>(() => QuestCreateController(listController));

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
