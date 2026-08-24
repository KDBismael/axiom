import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axiom/features/quests/services/focus_session_draft_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FocusSessionDraftStore', () {
    test('read returns null when nothing was saved', () async {
      final store = FocusSessionDraftStore();
      expect(await store.read('quest-1'), isNull);
    });

    test('save then read round-trips the draft', () async {
      final store = FocusSessionDraftStore();
      final draft = FocusSessionDraft(
        startedAt: DateTime.utc(2026, 1, 1, 9, 0),
        endedAt: DateTime.utc(2026, 1, 1, 9, 30),
      );

      await store.save('quest-1', draft);
      final read = await store.read('quest-1');

      expect(read?.startedAt, draft.startedAt);
      expect(read?.endedAt, draft.endedAt);
    });

    test('clear removes the draft', () async {
      final store = FocusSessionDraftStore();
      await store.save(
        'quest-1',
        FocusSessionDraft(
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 30),
        ),
      );

      await store.clear('quest-1');

      expect(await store.read('quest-1'), isNull);
    });

    test('drafts are scoped per quest id', () async {
      final store = FocusSessionDraftStore();
      await store.save(
        'quest-1',
        FocusSessionDraft(
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 30),
        ),
      );

      expect(await store.read('quest-2'), isNull);
      expect(await store.read('quest-1'), isNotNull);
    });
  });
}
