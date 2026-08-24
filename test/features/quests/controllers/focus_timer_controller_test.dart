import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/focus_timer_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/services/focus_chime_service.dart';
import 'package:axiom/features/quests/services/focus_presence_service.dart';
import 'package:axiom/features/quests/services/focus_session_draft_store.dart';

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
  late MockQuestListController mockQuestList;
  late MockFocusSessionDraftStore mockDraftStore;
  late MockFocusPresenceService mockPresence;
  late MockFocusChimeService mockChime;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      FocusSessionDraft(startedAt: DateTime(2026), endedAt: DateTime(2026)),
    );
  });

  setUp(() {
    mockQuestList = MockQuestListController();
    mockDraftStore = MockFocusSessionDraftStore();
    mockPresence = MockFocusPresenceService();
    mockChime = MockFocusChimeService();
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
  });

  FocusTimerController buildController({
    Duration tickInterval = const Duration(milliseconds: 5),
    Duration chimeInterval = const Duration(milliseconds: 20),
  }) {
    return FocusTimerController(
      mockQuestList,
      mockDraftStore,
      'q-1',
      presence: mockPresence,
      chime: mockChime,
      tickInterval: tickInterval,
      chimeInterval: chimeInterval,
    );
  }

  group('FocusTimerController.onInit', () {
    test('starts idle with no elapsed time when there is no pending draft', () async {
      final controller = buildController();
      controller.onInit();
      await Future.delayed(Duration.zero);

      expect(controller.state.value, FocusTimerState.idle);
      expect(controller.elapsed.value, Duration.zero);
      controller.onClose();
    });

    test('restores a pending draft as a finished session', () async {
      when(() => mockDraftStore.read('q-1')).thenAnswer(
        (_) async => FocusSessionDraft(
          startedAt: DateTime(2026, 1, 1, 9, 0),
          endedAt: DateTime(2026, 1, 1, 9, 30),
        ),
      );
      final controller = buildController();

      controller.onInit();
      await Future.delayed(Duration.zero);

      expect(controller.state.value, FocusTimerState.finished);
      expect(controller.elapsed.value, const Duration(minutes: 30));
      controller.onClose();
    });
  });

  group('FocusTimerController.start/pause/resume', () {
    test('start begins ticking and notifies the presence service', () async {
      final controller = buildController();

      await controller.start();
      await Future.delayed(const Duration(milliseconds: 30));

      expect(controller.state.value, FocusTimerState.running);
      expect(controller.elapsed.value, greaterThan(Duration.zero));
      verify(
        () => mockPresence.start(
          questTitle: 'Lire',
          startedAt: any(named: 'startedAt'),
        ),
      ).called(1);
      controller.onClose();
    });

    test('pause stops the ticker and keeps the accumulated elapsed time', () async {
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 30));

      controller.pause();
      final pausedElapsed = controller.elapsed.value;
      await Future.delayed(const Duration(milliseconds: 30));

      expect(controller.state.value, FocusTimerState.paused);
      expect(controller.elapsed.value, pausedElapsed);
      verify(() => mockPresence.pause()).called(1);
      controller.onClose();
    });

    test('resume continues ticking from where it paused', () async {
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 20));
      controller.pause();
      final pausedElapsed = controller.elapsed.value;

      await controller.resume();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state.value, FocusTimerState.running);
      expect(controller.elapsed.value, greaterThan(pausedElapsed));
      verify(() => mockPresence.resume()).called(1);
      controller.onClose();
    });

    test('plays the chime once per crossing of the chime interval', () async {
      final controller = buildController();
      await controller.start();

      await Future.delayed(const Duration(milliseconds: 55));
      controller.pause();

      // ~55ms of ticking at a 5ms tick / 20ms chime interval should cross
      // the chime at least twice (20ms, 40ms) without re-firing every tick.
      verify(() => mockChime.play()).called(greaterThanOrEqualTo(2));
      controller.onClose();
    });
  });

  group('FocusTimerController.finish', () {
    test('stops the ticker, persists a draft, and never touches the repository', () async {
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 20));

      await controller.finish();
      final finishedElapsed = controller.elapsed.value;
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state.value, FocusTimerState.finished);
      expect(controller.elapsed.value, finishedElapsed); // ticker is stopped
      expect(controller.startedAt, isNotNull);
      expect(controller.endedAt, isNotNull);
      verify(() => mockDraftStore.save('q-1', any())).called(1);
      verify(() => mockPresence.finish()).called(1);
      controller.onClose();
    });

    test('is a no-op when the timer was never started', () async {
      final controller = buildController();

      await controller.finish();

      expect(controller.state.value, FocusTimerState.idle);
      verifyNever(() => mockDraftStore.save(any(), any()));
      controller.onClose();
    });
  });

  group('FocusTimerController.reset', () {
    test('discards a finished session and clears the draft', () async {
      when(() => mockDraftStore.clear('q-1')).thenAnswer((_) async {});
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 20));
      await controller.finish();

      await controller.reset();

      expect(controller.state.value, FocusTimerState.idle);
      expect(controller.elapsed.value, Duration.zero);
      expect(controller.startedAt, isNull);
      expect(controller.endedAt, isNull);
      verify(() => mockDraftStore.clear('q-1')).called(1);
      controller.onClose();
    });

    test('is a no-op unless the session is finished', () async {
      final controller = buildController();

      await controller.reset();

      expect(controller.state.value, FocusTimerState.idle);
      verifyNever(() => mockDraftStore.clear(any()));
      controller.onClose();
    });

    test('starting again after reset begins a fresh session', () async {
      when(() => mockDraftStore.clear('q-1')).thenAnswer((_) async {});
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 20));
      await controller.finish();
      final firstStartedAt = controller.startedAt;
      await controller.reset();

      await controller.start();

      expect(controller.state.value, FocusTimerState.running);
      expect(controller.startedAt, isNot(firstStartedAt));
      controller.onClose();
    });
  });

  group('FocusTimerController.onClose', () {
    test('cancels the ticker so elapsed stops advancing', () async {
      final controller = buildController();
      await controller.start();
      await Future.delayed(const Duration(milliseconds: 20));

      controller.onClose();
      final elapsedAtClose = controller.elapsed.value;
      await Future.delayed(const Duration(milliseconds: 30));

      expect(controller.elapsed.value, elapsedAtClose);
    });
  });
}
