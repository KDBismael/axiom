import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/utils/quest_period_status.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel quest({int target = 1}) => QuestModel(
  id: 'q-1',
  title: 'Courir',
  description: '',
  frequency: QuestFrequency.daily,
  durationDays: 10,
  targetPerPeriod: target,
  startDate: DateTime.utc(2026, 7, 1),
  deadline: DateTime.utc(2026, 7, 10),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.medium,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: false,
  status: QuestStatus.active,
  progress: 0.1,
  streakDays: 1,
  creatorId: 'user-1',
);

CheckIn ci(int day, {List<Evidence> evidence = const []}) => CheckIn(
  id: 'ci-$day',
  questId: 'q-1',
  date: DateTime.utc(2026, 7, day),
  evidence: evidence,
);

void main() {
  test('a completed no-proof period is green', () {
    expect(
      questPeriodStatus(quest(), [ci(1)], 1, 3),
      QuestPeriodStatus.success,
    );
  });

  test('a missed past period is red, current incomplete is neutral', () {
    expect(
      questPeriodStatus(quest(), const [], 1, 3),
      QuestPeriodStatus.missed,
    );
    expect(
      questPeriodStatus(quest(), const [], 3, 3),
      QuestPeriodStatus.inProgress,
    );
    expect(
      questPeriodStatus(quest(), const [], 4, 3),
      QuestPeriodStatus.future,
    );
  });

  test('pending evidence counts provisionally, fully rejected does not', () {
    final pending = Evidence(
      id: 'e-1',
      proofType: ProofType.photo,
      status: EvidenceStatus.pending,
    );
    final rejected = Evidence(
      id: 'e-2',
      proofType: ProofType.photo,
      status: EvidenceStatus.rejected,
    );
    expect(
      questPeriodStatus(
        quest(),
        [
          ci(1, evidence: [pending]),
        ],
        1,
        3,
      ),
      QuestPeriodStatus.success,
    );
    expect(
      questPeriodStatus(
        quest(),
        [
          ci(1, evidence: [rejected]),
        ],
        1,
        3,
      ),
      QuestPeriodStatus.missed,
    );
  });

  test('a period only becomes complete after reaching its target count', () {
    expect(
      questPeriodStatus(quest(target: 2), [ci(1)], 1, 3),
      QuestPeriodStatus.missed,
    );
    expect(
      questPeriodStatus(quest(target: 2), [ci(1), ci(1)], 1, 3),
      QuestPeriodStatus.success,
    );
  });
}
