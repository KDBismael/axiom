import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/utils/period_progress.dart';

void main() {
  group('countCheckInsInCurrentPeriod', () {
    final now = DateTime(2026, 7, 10); // Friday

    CheckIn ci(DateTime date) => CheckIn(id: 'ci', questId: 'q-1', date: date);

    test('counts only check-ins on the same calendar day for daily quests', () {
      final checkIns = [
        ci(DateTime(2026, 7, 10, 8)),
        ci(DateTime(2026, 7, 10, 20)),
        ci(DateTime(2026, 7, 9)),
      ];
      expect(
        countCheckInsInCurrentPeriod(
          checkIns,
          QuestFrequency.daily,
          now,
          startDate: DateTime(2026, 7, 1),
        ),
        2,
      );
    });

    test('returns 0 when no check-ins fall in the current day', () {
      final checkIns = [ci(DateTime(2026, 7, 9))];
      expect(
        countCheckInsInCurrentPeriod(
          checkIns,
          QuestFrequency.daily,
          now,
          startDate: DateTime(2026, 7, 1),
        ),
        0,
      );
    });

    test('counts check-ins in the seven-day period anchored at the start', () {
      // Started Wednesday 07-08; its first period ends Tuesday 07-14.
      final checkIns = [
        ci(DateTime(2026, 7, 8)),
        ci(DateTime(2026, 7, 13)),
        ci(DateTime(2026, 7, 7)),
        ci(DateTime(2026, 7, 15)),
      ];
      expect(
        countCheckInsInCurrentPeriod(
          checkIns,
          QuestFrequency.weekly,
          now,
          startDate: DateTime(2026, 7, 8),
        ),
        2,
      );
    });

    test('returns 0 for an empty check-in list', () {
      expect(
        countCheckInsInCurrentPeriod(
          const [],
          QuestFrequency.daily,
          now,
          startDate: DateTime(2026, 7, 1),
        ),
        0,
      );
    });
  });
}
