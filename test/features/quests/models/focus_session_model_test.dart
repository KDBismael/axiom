import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/focus_session_model.dart';

void main() {
  group('FocusSession.fromJson', () {
    test('parses a session row', () {
      final session = FocusSession.fromJson({
        'id': 'focus-1',
        'questId': 'q-1',
        'startedAt': '2026-01-07T09:00:00.000Z',
        'endedAt': '2026-01-07T09:30:00.000Z',
        'durationMinutes': 30,
      });

      expect(session.id, 'focus-1');
      expect(session.questId, 'q-1');
      expect(session.durationMinutes, 30);
      expect(session.startedAt, DateTime.parse('2026-01-07T09:00:00.000Z'));
    });
  });

  group('FocusSessionHistory.fromJson', () {
    test('parses sessions and todayMinutes', () {
      final history = FocusSessionHistory.fromJson({
        'sessions': [
          {
            'id': 'focus-1',
            'questId': 'q-1',
            'startedAt': '2026-01-07T09:00:00.000Z',
            'endedAt': '2026-01-07T09:30:00.000Z',
            'durationMinutes': 30,
          },
        ],
        'todayMinutes': 30,
      });

      expect(history.sessions, hasLength(1));
      expect(history.todayMinutes, 30);
    });

    test('defaults to an empty list and zero minutes', () {
      final history = FocusSessionHistory.fromJson({});

      expect(history.sessions, isEmpty);
      expect(history.todayMinutes, 0);
    });
  });
}
