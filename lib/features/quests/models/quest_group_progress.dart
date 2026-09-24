import 'quest_model.dart';

/// One member's status within a collective quest — their own Quest's
/// progress/streak, computed the exact same way a solo quest's is.
/// `GET /quests/groups/:groupId/progress`.
class QuestGroupMemberProgress {
  const QuestGroupMemberProgress({
    required this.userId,
    required this.questId,
    required this.status,
    required this.progress,
    required this.streakDays,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  final String userId;
  final String questId;
  final QuestStatus status;

  /// 0-1.
  final double progress;
  final int streakDays;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  String get name => [
    firstName,
    lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestGroupMemberProgress.fromJson(Map<String, dynamic> json) {
    return QuestGroupMemberProgress(
      userId: json['userId'] as String,
      questId: json['questId'] as String,
      status: QuestStatus.fromJson(json['status'] as String),
      progress: (json['progress'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class QuestGroupProgress {
  const QuestGroupProgress({
    required this.groupId,
    required this.groupTitle,
    required this.creatorId,
    required this.members,
  });

  final String groupId;
  final String groupTitle;
  final String creatorId;
  final List<QuestGroupMemberProgress> members;

  factory QuestGroupProgress.fromJson(Map<String, dynamic> json) {
    return QuestGroupProgress(
      groupId: json['groupId'] as String,
      groupTitle: json['groupTitle'] as String,
      creatorId: json['creatorId'] as String,
      members: (json['members'] as List)
          .map(
            (m) =>
                QuestGroupMemberProgress.fromJson(m as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
