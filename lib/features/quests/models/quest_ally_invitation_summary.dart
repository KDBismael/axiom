/// A row in the "quests you've been invited to ally on" list —
/// `GET /quests/ally-invitations`. Deliberately minimal (just enough to
/// render a list row); tapping through fetches the full terms via
/// [QuestAllyInvitation]/`GET /quests/:id/ally-invitation`.
class QuestAllyInvitationSummary {
  const QuestAllyInvitationSummary({
    required this.questId,
    required this.questTitle,
    required this.invitedAt,
  });

  final String questId;
  final String questTitle;
  final DateTime invitedAt;

  factory QuestAllyInvitationSummary.fromJson(Map<String, dynamic> json) {
    return QuestAllyInvitationSummary(
      questId: json['questId'] as String,
      questTitle: json['questTitle'] as String,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
    );
  }
}
