import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/utils/streak_summary.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel quest(QuestFrequency frequency, int streak) => QuestModel(
  id: 'q-$frequency-$streak',
  title: 'Courir',
  description: '',
  frequency: frequency,
  durationDays: 30,
  targetPerPeriod: 1,
  startDate: DateTime.utc(2026, 7, 1),
  deadline: DateTime.utc(2026, 7, 31),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.medium,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: false,
  status: QuestStatus.active,
  progress: 0,
  streakDays: streak,
  creatorId: 'user-1',
);

void main() {
  group('bestStreak', () {
    test('no quests is a zero-day streak', () {
      final best = bestStreak([]);
      expect(best.count, 0);
      expect(best.label, 'jour sans rupture');
    });

    test('keeps the weekly unit of a weekly quest', () {
      final best = bestStreak([quest(QuestFrequency.weekly, 11)]);
      expect(best.count, 11);
      expect(best.label, 'semaines sans rupture');
    });

    test('compares streaks by elapsed time, not raw count', () {
      final best = bestStreak([
        quest(QuestFrequency.daily, 5),
        quest(QuestFrequency.weekly, 3),
      ]);
      expect(best.count, 3);
      expect(best.label, 'semaines sans rupture');
    });

    test('a longer daily streak beats a shorter weekly one', () {
      final best = bestStreak([
        quest(QuestFrequency.weekly, 1),
        quest(QuestFrequency.daily, 9),
      ]);
      expect(best.count, 9);
      expect(best.label, 'jours sans rupture');
    });
  });

  group('streakUnit', () {
    test('singular for zero and one, plural above', () {
      expect(streakUnit(QuestFrequency.daily, 0), 'jour');
      expect(streakUnit(QuestFrequency.daily, 1), 'jour');
      expect(streakUnit(QuestFrequency.daily, 2), 'jours');
      expect(streakUnit(QuestFrequency.weekly, 1), 'semaine');
      expect(streakUnit(QuestFrequency.weekly, 4), 'semaines');
    });
  });
}
