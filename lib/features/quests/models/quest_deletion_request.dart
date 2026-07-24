enum QuestDeletionRequestStatus {
  pending,
  approved,
  rejected;

  factory QuestDeletionRequestStatus.fromJson(String value) =>
      QuestDeletionRequestStatus.values.firstWhere((v) => v.name == value);
}

class QuestDeletionVoteTally {
  const QuestDeletionVoteTally({required this.approved, required this.total});

  final int approved;
  final int total;

  factory QuestDeletionVoteTally.fromJson(Map<String, dynamic> json) {
    return QuestDeletionVoteTally(
      approved: json['approved'] as int,
      total: json['total'] as int,
    );
  }
}

/// A pending/resolved deletion request for a quest with accepted allies —
/// `GET /quests/:id/delete-request`.
class QuestDeletionRequest {
  const QuestDeletionRequest({
    required this.id,
    required this.status,
    required this.votes,
  });

  final String id;
  final QuestDeletionRequestStatus status;
  final QuestDeletionVoteTally votes;

  factory QuestDeletionRequest.fromJson(Map<String, dynamic> json) {
    return QuestDeletionRequest(
      id: json['id'] as String,
      status: QuestDeletionRequestStatus.fromJson(json['status'] as String),
      votes: QuestDeletionVoteTally.fromJson(
        json['votes'] as Map<String, dynamic>,
      ),
    );
  }
}

/// The immediate result of `POST /quests/:id/delete-request`: either the
/// quest was resolved right away (deleted, or cancelled with a refund) or a
/// pending request was created awaiting the quest's allies to vote.
class QuestDeletionOutcome {
  const QuestDeletionOutcome({
    required this.deleted,
    required this.pending,
    this.cancelled = false,
    this.requestId,
    this.votes,
  });

  final bool deleted;
  final bool pending;
  final bool cancelled;
  final String? requestId;
  final QuestDeletionVoteTally? votes;

  factory QuestDeletionOutcome.fromJson(Map<String, dynamic> json) {
    return QuestDeletionOutcome(
      deleted: json['deleted'] as bool,
      pending: json['pending'] as bool,
      cancelled: json['cancelled'] as bool? ?? false,
      requestId: json['requestId'] as String?,
      votes: json['votes'] == null
          ? null
          : QuestDeletionVoteTally.fromJson(
              json['votes'] as Map<String, dynamic>,
            ),
    );
  }
}
