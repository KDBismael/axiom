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
      expect(countCheckInsInCurrentPeriod(checkIns, QuestFrequency.daily, now), 2);
    });

    test('returns 0 when no check-ins fall in the current day', () {
      final checkIns = [ci(DateTime(2026, 7, 9))];
      expect(countCheckInsInCurrentPeriod(checkIns, QuestFrequency.daily, now), 0);
    });

    test('counts only check-ins in the same ISO week for weekly quests', () {
      // 2026-07-10 is a Friday; the ISO week is Mon 07-06 .. Sun 07-12.
      final checkIns = [
        ci(DateTime(2026, 7, 6)), // Monday, same week
        ci(DateTime(2026, 7, 12)), // Sunday, same week
        ci(DateTime(2026, 7, 13)), // next Monday, different week
        ci(DateTime(2026, 6, 29)), // previous week
      ];
      expect(countCheckInsInCurrentPeriod(checkIns, QuestFrequency.weekly, now), 2);
    });

    test('returns 0 for an empty check-in list', () {
      expect(countCheckInsInCurrentPeriod(const [], QuestFrequency.daily, now), 0);
    });
  });
}
