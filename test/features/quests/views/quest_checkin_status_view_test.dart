import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/views/quest_checkin_status_view.dart';
import 'package:axiom/features/rank/controllers/rank_controller.dart';
import 'package:axiom/features/rank/models/leaderboard_entry.dart';
import 'package:axiom/features/rank/models/rank_summary.dart';
import 'package:axiom/features/rank/models/trophy_item.dart';
import 'package:axiom/features/rank/repositories/rank_repository.dart';
import 'package:axiom/features/shell/controllers/shell_controller.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

class MockRankRepository extends Mock implements RankRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  Future<void> pumpCelebration(
    WidgetTester tester, {
    required bool requiresProof,
    required CheckInResult result,
  }) async {
    final mockQuestRepository = MockQuestRepository();
    when(() => mockQuestRepository.fetchQuests()).thenAnswer(
      (_) async => [
        QuestModel(
          id: '1',
          title: 'Gym 3x par semaine',
          description: '',
          creatorId: 'user-1',
          frequency: QuestFrequency.weekly,
          durationDays: 30,
          targetPerPeriod: 1,
          startDate: DateTime(2026, 1, 1),
          deadline: DateTime(2026, 2, 1),
          gracePeriodDays: 0,
          riskLevel: QuestRiskLevel.medium,
          requiresProof: requiresProof,
          successThresholdPercent: 80,
          hasStake: false,
          status: QuestStatus.active,
          progress: 0.5,
          streakDays: 12,
        ),
      ],
    );
    when(
      () => mockQuestRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockQuestRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockQuestRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => mockQuestRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);

    Get.put<ShellController>(ShellController());
    Get.put<QuestListController>(QuestListController(mockQuestRepository));

    final mockRankRepository = MockRankRepository();
    when(() => mockRankRepository.fetchRank()).thenAnswer(
      (_) async => const RankSummary(
        totalPoints: 140,
        tier: 'Bronze',
        tierIndex: 0,
        subLevel: 'I',
        subLevelIndex: 0,
        rankLabel: 'Bronze I',
        pointsIntoTier: 140,
        pointsIntoSubLevel: 140,
        pointsToNextSubLevel: 360,
        pointsToNextTier: 1360,
        isMaxRank: false,
      ),
    );
    when(
      () => mockRankRepository.fetchTrophies(),
    ).thenAnswer((_) async => const <TrophyItem>[]);
    when(
      () => mockRankRepository.fetchLeaderboard(),
    ).thenAnswer((_) async => const <LeaderboardEntry>[]);
    Get.put<RankController>(RankController(mockRankRepository));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(
            name: '/quest-checkin-status',
            page: () => const QuestCheckinStatusView(),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed(
      '/quest-checkin-status',
      arguments: {
        'questId': '1',
        'requiresProof': requiresProof,
        'result': result,
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    tester.takeException();
  }

  testWidgets('a no-proof quest shows no points line and a plain confirmation', (
    tester,
  ) async {
    final result = CheckInResult(
      checkIn: CheckIn(id: 'ci-1', questId: '1', date: DateTime.now()),
      streakDays: 12,
      progress: 0.5,
      currentPeriodCount: 1,
      targetPerPeriod: 1,
    );

    await pumpCelebration(tester, requiresProof: false, result: result);

    expect(find.text('Combo ×12'), findsOneWidget);
    expect(
      find.text('Check-in enregistré. Continue comme ça.'),
      findsOneWidget,
    );
    expect(find.textContaining('PTS'), findsNothing);
    expect(find.text('CONTINUER'), findsOneWidget);
  });

  testWidgets('a proof-required quest shows the provisional pending points line', (
    tester,
  ) async {
    final result = CheckInResult(
      checkIn: CheckIn(id: 'ci-1', questId: '1', date: DateTime.now()),
      streakDays: 12,
      progress: 0.5,
      currentPeriodCount: 1,
      targetPerPeriod: 1,
      evidence: const Evidence(
        id: 'ev-1',
        proofType: ProofType.text,
        status: EvidenceStatus.pending,
        textContent: 'fait',
      ),
    );

    await pumpCelebration(tester, requiresProof: true, result: result);

    expect(find.text('Preuve envoyée. Tes alliés vont la juger.'), findsOneWidget);
    expect(find.text('+20 PTS · EN ATTENTE'), findsOneWidget);
  });

  testWidgets('a partial multi-check-in period shows the pointage count, not a combo', (
    tester,
  ) async {
    final result = CheckInResult(
      checkIn: CheckIn(id: 'ci-1', questId: '1', date: DateTime.now()),
      streakDays: 12,
      progress: 0.5,
      currentPeriodCount: 1,
      targetPerPeriod: 2,
    );

    await pumpCelebration(tester, requiresProof: false, result: result);

    // The fixture quest in pumpCelebration() is weekly, so the partial-
    // period label reads "cette semaine", not "aujourd'hui".
    expect(find.textContaining('Combo'), findsNothing);
    expect(find.text('1/2 cette semaine'), findsOneWidget);
  });
}
