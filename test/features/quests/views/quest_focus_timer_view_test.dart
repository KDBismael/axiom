import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/focus_timer_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/services/focus_chime_service.dart';
import 'package:axiom/features/quests/services/focus_presence_service.dart';
import 'package:axiom/features/quests/services/focus_session_draft_store.dart';
import 'package:axiom/features/quests/views/quest_focus_timer_view.dart';

class MockQuestListController extends Mock implements QuestListController {}

class MockFocusSessionDraftStore extends Mock
    implements FocusSessionDraftStore {}

class MockFocusPresenceService extends Mock implements FocusPresenceService {}

class MockFocusChimeService extends Mock implements FocusChimeService {}

QuestModel _quest() => QuestModel(
  id: 'q-1',
  title: 'Lire',
  description: '',
  creatorId: 'user-1',
  frequency: QuestFrequency.daily,
  durationDays: 30,
  targetPerPeriod: 1,
  startDate: DateTime(2026, 1, 1),
  deadline: DateTime(2026, 1, 31),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.medium,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: false,
  status: QuestStatus.active,
  progress: 0,
  streakDays: 0,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      FocusSessionDraft(startedAt: DateTime(2026), endedAt: DateTime(2026)),
    );
  });

  tearDown(Get.reset);

  /// Regression guard for a real crash: every state this view renders
  /// (idle/running/paused/finished) must lay out without throwing —
  /// specifically an `AppButton` with its default `fullWidth: true` inside
  /// a `Row(mainAxisSize: MainAxisSize.min)` demands infinite width and
  /// crashes RenderFlex layout.
  testWidgets('renders every timer state without a layout exception', (
    tester,
  ) async {
    final mockQuestList = MockQuestListController();
    final mockDraftStore = MockFocusSessionDraftStore();
    final mockPresence = MockFocusPresenceService();
    final mockChime = MockFocusChimeService();
    when(() => mockQuestList.findById('q-1')).thenReturn(_quest());
    when(() => mockDraftStore.read('q-1')).thenAnswer((_) async => null);
    when(() => mockDraftStore.save(any(), any())).thenAnswer((_) async {});
    when(
      () => mockPresence.start(
        questTitle: any(named: 'questTitle'),
        startedAt: any(named: 'startedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockPresence.pause()).thenAnswer((_) async {});
    when(() => mockPresence.resume()).thenAnswer((_) async {});
    when(() => mockPresence.finish()).thenAnswer((_) async {});
    when(() => mockChime.play()).thenAnswer((_) async {});

    final controller = FocusTimerController(
      mockQuestList,
      mockDraftStore,
      'q-1',
      presence: mockPresence,
      chime: mockChime,
      tickInterval: const Duration(milliseconds: 5),
    );
    Get.put<FocusTimerController>(controller, tag: 'q-1');

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(
            name: '/quest-focus-timer',
            page: () => const QuestFocusTimerView(),
          ),
        ],
      ),
    );
    await tester.pump();
    Get.toNamed('/quest-focus-timer', arguments: 'q-1');
    await tester.pumpAndSettle();

    // idle
    expect(tester.takeException(), isNull);

    // running
    await controller.start();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // paused
    controller.pause();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // running again (resume)
    await controller.resume();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // finished
    await controller.finish();
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.onClose();
  });
}
