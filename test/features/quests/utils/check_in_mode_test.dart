import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/utils/check_in_mode.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel quest({
  bool requiresProof = false,
  List<QuestAllyStatus> allies = const [],
}) => QuestModel(
  id: 'q-1',
  title: 'Lire 10 pages',
  description: '',
  creatorId: 'user-1',
  frequency: QuestFrequency.daily,
  durationDays: 30,
  targetPerPeriod: 1,
  startDate: DateTime(2026, 11, 7),
  deadline: DateTime(2026, 12, 7),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.low,
  requiresProof: requiresProof,
  successThresholdPercent: 80,
  hasStake: false,
  status: QuestStatus.active,
  progress: 0,
  streakDays: 0,
  allies: [
    for (final (i, status) in allies.indexed)
      QuestAllyRef(
        userId: 'ally-$i',
        firstName: 'Allié',
        lastName: '$i',
        status: status,
      ),
  ],
);

void main() {
  test('optional proof and no accepted ally: plain self check-in', () {
    expect(checkInModeFor(quest()), CheckInMode.selfCheckIn);
    expect(
      checkInModeFor(quest(allies: [QuestAllyStatus.pending])),
      CheckInMode.selfCheckIn,
    );
  });

  test('optional proof with an accepted ally: proof can be attached', () {
    expect(
      checkInModeFor(quest(allies: [QuestAllyStatus.accepted])),
      CheckInMode.proofOptional,
    );
  });

  test('required proof with an accepted ally', () {
    expect(
      checkInModeFor(
        quest(requiresProof: true, allies: [QuestAllyStatus.accepted]),
      ),
      CheckInMode.proofRequired,
    );
  });

  test('required proof but nobody to review it', () {
    expect(
      checkInModeFor(quest(requiresProof: true)),
      CheckInMode.proofRequiredNoAlly,
    );
  });
}
