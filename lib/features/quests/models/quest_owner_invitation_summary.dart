/// A row in the "quests offered to you" list — `GET /quests/owner-invitations`.
/// Deliberately minimal (just enough to render a list row); tapping through
/// fetches the full terms via [QuestOwnerInvitation]/
/// `GET /quests/:id/owner-invitation`.
class QuestOwnerInvitationSummary {
  const QuestOwnerInvitationSummary({
    required this.questId,
    required this.questTitle,
    required this.invitedAt,
    this.creatorFirstName,
    this.creatorLastName,
    this.creatorAvatarUrl,
  });

  final String questId;
  final String questTitle;
  final DateTime invitedAt;
  final String? creatorFirstName;
  final String? creatorLastName;
  final String? creatorAvatarUrl;

  String get creatorName => [
    creatorFirstName,
    creatorLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestOwnerInvitationSummary.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    return QuestOwnerInvitationSummary(
      questId: json['questId'] as String,
      questTitle: json['questTitle'] as String,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      creatorFirstName: creator?['firstName'] as String?,
      creatorLastName: creator?['lastName'] as String?,
      creatorAvatarUrl: creator?['avatarUrl'] as String?,
    );
  }
}
