import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/utils/check_in_availability.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel quest({
  QuestFrequency frequency = QuestFrequency.daily,
  int target = 1,
  QuestStatus status = QuestStatus.active,
  DateTime? deadline,
}) => QuestModel(
  id: 'q-1',
  title: 'Courir 5 km',
  description: '',
  frequency: frequency,
  durationDays: 10,
  targetPerPeriod: target,
  startDate: DateTime.utc(2026, 7, 8),
  deadline: deadline ?? DateTime.utc(2026, 7, 18),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.medium,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: false,
  status: status,
  progress: 0.37,
  streakDays: 9,
  creatorId: 'user-1',
);

CheckIn checkIn(int day) =>
    CheckIn(id: 'ci-$day', questId: 'q-1', date: DateTime.utc(2026, 7, day));

void main() {
  final now = DateTime.utc(2026, 7, 10, 16);

  test('completed daily objective shows done state', () {
    expect(
      checkInAvailability(quest(), [checkIn(10)], now),
      CheckInAvailability.periodComplete,
    );
  });

  test(
    'multi-check-in objective remains available until target is reached',
    () {
      expect(
        checkInAvailability(quest(target: 2), [checkIn(10)], now),
        CheckInAvailability.available,
      );
      expect(
        checkInAvailability(quest(target: 2), [checkIn(10), checkIn(10)], now),
        CheckInAvailability.periodComplete,
      );
    },
  );

  test('weekly target uses the quest start date, not calendar week', () {
    expect(
      checkInAvailability(quest(frequency: QuestFrequency.weekly, target: 2), [
        checkIn(8),
        checkIn(13),
      ], now),
      CheckInAvailability.periodComplete,
    );
  });

  test('expired active quest no longer offers validation', () {
    expect(
      checkInAvailability(
        quest(deadline: DateTime.utc(2026, 7, 9)),
        const [],
        now,
      ),
      CheckInAvailability.deadlinePassed,
    );
  });

  test('paused quest no longer offers validation', () {
    expect(
      checkInAvailability(quest(status: QuestStatus.paused), const [], now),
      CheckInAvailability.inactive,
    );
  });
}
