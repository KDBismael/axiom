/// A row in the "quests you've been invited to ally on" list —
/// `GET /quests/ally-invitations`. Deliberately minimal (just enough to
/// render a list row); tapping through fetches the full terms via
/// [QuestAllyInvitation]/`GET /quests/:id/ally-invitation`.
class QuestAllyInvitationSummary {
  const QuestAllyInvitationSummary({
    required this.questId,
    required this.questTitle,
    required this.invitedAt,
    this.inviterFirstName,
    this.inviterLastName,
    this.inviterAvatarUrl,
  });

  final String questId;
  final String questTitle;
  final DateTime invitedAt;
  final String? inviterFirstName;
  final String? inviterLastName;
  final String? inviterAvatarUrl;

  String get inviterName => [
    inviterFirstName,
    inviterLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestAllyInvitationSummary.fromJson(Map<String, dynamic> json) {
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return QuestAllyInvitationSummary(
      questId: json['questId'] as String,
      questTitle: json['questTitle'] as String,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      inviterFirstName: inviter?['firstName'] as String?,
      inviterLastName: inviter?['lastName'] as String?,
      inviterAvatarUrl: inviter?['avatarUrl'] as String?,
    );
  }
}
