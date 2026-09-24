/// A row in the "collective quests you've been invited to" list —
/// `GET /quests/groups/invitations`. Deliberately minimal (just enough to
/// render a list row); tapping through fetches the full terms via
/// [QuestGroupInvitation]/`GET /quests/groups/:groupId/invitation`.
class QuestGroupInvitationSummary {
  const QuestGroupInvitationSummary({
    required this.groupId,
    required this.groupTitle,
    required this.invitedAt,
    this.inviterFirstName,
    this.inviterLastName,
    this.inviterAvatarUrl,
  });

  final String groupId;
  final String groupTitle;
  final DateTime invitedAt;
  final String? inviterFirstName;
  final String? inviterLastName;
  final String? inviterAvatarUrl;

  String get inviterName => [
    inviterFirstName,
    inviterLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestGroupInvitationSummary.fromJson(Map<String, dynamic> json) {
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return QuestGroupInvitationSummary(
      groupId: json['groupId'] as String,
      groupTitle: json['groupTitle'] as String,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      inviterFirstName: inviter?['firstName'] as String?,
      inviterLastName: inviter?['lastName'] as String?,
      inviterAvatarUrl: inviter?['avatarUrl'] as String?,
    );
  }
}
