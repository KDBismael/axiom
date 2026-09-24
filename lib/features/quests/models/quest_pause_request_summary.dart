/// A row in "pause requests awaiting your decision" — across every quest the
/// caller is an accepted ally on. `GET /quests/pause-requests`.
class QuestPauseRequestSummary {
  const QuestPauseRequestSummary({
    required this.requestId,
    required this.questId,
    required this.questTitle,
    required this.createdAt,
    this.requesterFirstName,
    this.requesterLastName,
    this.requesterAvatarUrl,
  });

  final String requestId;
  final String questId;
  final String questTitle;
  final DateTime createdAt;
  final String? requesterFirstName;
  final String? requesterLastName;
  final String? requesterAvatarUrl;

  String get requesterName => [
    requesterFirstName,
    requesterLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestPauseRequestSummary.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'] as Map<String, dynamic>?;
    return QuestPauseRequestSummary(
      requestId: json['requestId'] as String,
      questId: json['questId'] as String,
      questTitle: json['questTitle'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      requesterFirstName: requester?['firstName'] as String?,
      requesterLastName: requester?['lastName'] as String?,
      requesterAvatarUrl: requester?['avatarUrl'] as String?,
    );
  }
}
