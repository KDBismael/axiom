import '../models/quest_model.dart';

/// How the "VALIDER" screen should behave for a quest. Proofs are reviewed
/// by the quest's accepted allies, so the backend refuses a proof when
/// nobody can review it — the screen must never offer one in that case.
enum CheckInMode {
  /// Optional proof, no accepted ally yet: a one-tap check-in, no proof.
  selfCheckIn,

  /// Optional proof, at least one accepted ally to review it.
  proofOptional,

  /// Proof required and someone can review it.
  proofRequired,

  /// Proof required but no accepted ally: blocked until one accepts.
  proofRequiredNoAlly,
}

CheckInMode checkInModeFor(QuestModel quest) {
  final hasReviewer = quest.allies.any(
    (ally) => ally.status == QuestAllyStatus.accepted,
  );
  if (quest.requiresProof) {
    return hasReviewer
        ? CheckInMode.proofRequired
        : CheckInMode.proofRequiredNoAlly;
  }
  return hasReviewer ? CheckInMode.proofOptional : CheckInMode.selfCheckIn;
}
