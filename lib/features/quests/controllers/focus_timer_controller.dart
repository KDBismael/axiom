import 'dart:async';

import 'package:get/get.dart';
import '../services/focus_chime_service.dart';
import '../services/focus_presence_service.dart';
import '../services/focus_session_draft_store.dart';
import 'quest_list_controller.dart';

enum FocusTimerState { idle, running, paused, finished }

/// Drives the focus timer: start/pause/resume/finish, a chime every 25
/// minutes of active time, and a live "outside the app" presence
/// (`FocusPresenceService`). Finish never talks to the backend directly —
/// it only persists the session locally via [FocusSessionDraftStore]; the
/// actual check-in submission happens from `quest_validation_view.dart`
/// (see the plan's "no auto-submit on finish" decision).
class FocusTimerController extends GetxController {
  FocusTimerController(
    this._questList,
    this._draftStore,
    this.questId, {
    FocusPresenceService? presence,
    FocusChimeService? chime,
    Duration tickInterval = const Duration(seconds: 1),
    this.chimeInterval = const Duration(minutes: 25),
  }) : _presence = presence ?? DefaultFocusPresenceService(),
       _chime = chime ?? FocusChimeService(),
       _tickInterval = tickInterval;

  final QuestListController _questList;
  final FocusSessionDraftStore _draftStore;
  final String questId;
  final FocusPresenceService _presence;
  final FocusChimeService _chime;
  final Duration _tickInterval;

  /// How often the chime plays, measured in accumulated active [elapsed]
  /// time — overridable in tests so a chime crossing doesn't require
  /// waiting out a real 25 minutes.
  final Duration chimeInterval;

  final state = FocusTimerState.idle.obs;
  final elapsed = Duration.zero.obs;

  DateTime? _startedAt;
  DateTime? _endedAt;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _restoreDraftIfAny();
  }

  Future<void> _restoreDraftIfAny() async {
    final draft = await _draftStore.read(questId);
    if (draft == null) return;
    _startedAt = draft.startedAt;
    _endedAt = draft.endedAt;
    elapsed.value = draft.endedAt.difference(draft.startedAt);
    state.value = FocusTimerState.finished;
  }

  Future<void> start() async {
    if (state.value == FocusTimerState.running) return;
    _startedAt ??= DateTime.now();
    state.value = FocusTimerState.running;
    _startTicker();
    final quest = _questList.findById(questId);
    await _presence.start(
      questTitle: quest?.title ?? '',
      startedAt: _startedAt!,
    );
  }

  void pause() {
    if (state.value != FocusTimerState.running) return;
    _stopTicker();
    state.value = FocusTimerState.paused;
    _presence.pause();
  }

  Future<void> resume() async {
    if (state.value != FocusTimerState.paused) return;
    state.value = FocusTimerState.running;
    _startTicker();
    await _presence.resume();
  }

  Future<void> finish() async {
    if (state.value != FocusTimerState.running &&
        state.value != FocusTimerState.paused) {
      return;
    }
    _stopTicker();
    _endedAt = DateTime.now();
    await _draftStore.save(
      questId,
      FocusSessionDraft(startedAt: _startedAt!, endedAt: _endedAt!),
    );
    state.value = FocusTimerState.finished;
    await _presence.finish();
  }

  /// Discards a finished-but-not-yet-submitted session and goes back to
  /// [FocusTimerState.idle] — the user changed their mind about sending
  /// this pointage rather than wanting to submit it.
  Future<void> reset() async {
    if (state.value != FocusTimerState.finished) return;
    await _draftStore.clear(questId);
    _startedAt = null;
    _endedAt = null;
    elapsed.value = Duration.zero;
    state.value = FocusTimerState.idle;
  }

  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    elapsed.value += _tickInterval;
    final elapsedMs = elapsed.value.inMilliseconds;
    final intervalMs = chimeInterval.inMilliseconds;
    if (elapsedMs > 0 && elapsedMs % intervalMs == 0) {
      _chime.play();
    }
  }

  @override
  void onClose() {
    _stopTicker();
    _chime.dispose();
    super.onClose();
  }
}
