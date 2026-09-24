import 'quest_model.dart';

/// Full terms of a collective quest a friend was invited to join — shown
/// before they accept/decline, since accepting creates their own Quest with
/// these exact rules and makes them a validator for every current member
/// (and every current member a validator for them). No stake fields —
/// collective quests are unstaked-only. `GET /quests/groups/:groupId/invitation`.
class QuestGroupInvitation {
  const QuestGroupInvitation({
    required this.status,
    required this.groupId,
    required this.title,
    required this.description,
    required this.frequency,
    required this.durationDays,
    required this.targetPerPeriod,
    required this.startDate,
    required this.deadline,
    required this.gracePeriodDays,
    required this.riskLevel,
    required this.requiresProof,
    required this.successThresholdPercent,
    required this.memberCount,
    this.inviterFirstName,
    this.inviterLastName,
    this.inviterAvatarUrl,
  });

  final QuestGroupInvitationStatus status;
  final String groupId;
  final String title;
  final String description;
  final QuestFrequency frequency;
  final int durationDays;
  final int targetPerPeriod;
  final DateTime startDate;
  final DateTime deadline;
  final int gracePeriodDays;
  final QuestRiskLevel riskLevel;
  final bool requiresProof;
  final int successThresholdPercent;

  /// How many people are already in the group (including the creator).
  final int memberCount;

  final String? inviterFirstName;
  final String? inviterLastName;
  final String? inviterAvatarUrl;

  String get inviterName => [
    inviterFirstName,
    inviterLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  factory QuestGroupInvitation.fromJson(Map<String, dynamic> json) {
    final invitation = json['invitation'] as Map<String, dynamic>;
    final group = json['group'] as Map<String, dynamic>;
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return QuestGroupInvitation(
      status: QuestGroupInvitationStatus.fromJson(
        invitation['status'] as String,
      ),
      groupId: group['id'] as String,
      title: group['title'] as String,
      description: group['description'] as String,
      frequency: QuestFrequency.fromJson(group['frequency'] as String),
      durationDays: group['durationDays'] as int,
      targetPerPeriod: group['targetPerPeriod'] as int,
      startDate: DateTime.parse(group['startDate'] as String),
      deadline: DateTime.parse(group['deadline'] as String),
      gracePeriodDays: group['gracePeriodDays'] as int,
      riskLevel: QuestRiskLevel.fromJson(group['riskLevel'] as String),
      requiresProof: group['requiresProof'] as bool,
      successThresholdPercent: group['successThresholdPercent'] as int,
      memberCount: json['memberCount'] as int,
      inviterFirstName: inviter?['firstName'] as String?,
      inviterLastName: inviter?['lastName'] as String?,
      inviterAvatarUrl: inviter?['avatarUrl'] as String?,
    );
  }
}
