import 'quest_model.dart';

/// Full terms of a quest a friend was offered ownership of — shown before
/// they accept/decline, since accepting means committing to actually do the
/// habit (the creator becomes an accountability partner instead).
/// `GET /quests/:id/owner-invitation`.
class QuestOwnerInvitation {
  const QuestOwnerInvitation({
    required this.status,
    required this.questId,
    required this.title,
    required this.description,
    required this.frequency,
    required this.durationDays,
    required this.startDate,
    required this.deadline,
    required this.hasStake,
    this.creatorId,
    this.creatorFirstName,
    this.creatorLastName,
    this.creatorAvatarUrl,
    this.stakeAmountXof,
    this.fundsDistribution,
  });

  final QuestOwnerInvitationStatus status;
  final String questId;
  final String title;
  final String description;
  final QuestFrequency frequency;
  final int durationDays;
  final DateTime startDate;
  final DateTime deadline;
  final bool hasStake;
  final String? creatorId;
  final String? creatorFirstName;
  final String? creatorLastName;
  final String? creatorAvatarUrl;
  final double? stakeAmountXof;
  final FundsDistribution? fundsDistribution;

  factory QuestOwnerInvitation.fromJson(Map<String, dynamic> json) {
    final invitation = json['invitation'] as Map<String, dynamic>;
    final quest = json['quest'] as Map<String, dynamic>;
    final creator = json['creator'] as Map<String, dynamic>?;
    return QuestOwnerInvitation(
      status: QuestOwnerInvitationStatus.fromJson(
        invitation['status'] as String,
      ),
      questId: quest['id'] as String,
      title: quest['title'] as String,
      description: quest['description'] as String,
      frequency: QuestFrequency.fromJson(quest['frequency'] as String),
      durationDays: quest['durationDays'] as int,
      startDate: DateTime.parse(quest['startDate'] as String),
      deadline: DateTime.parse(quest['deadline'] as String),
      hasStake: quest['hasStake'] as bool,
      creatorId: creator?['id'] as String?,
      creatorFirstName: creator?['firstName'] as String?,
      creatorLastName: creator?['lastName'] as String?,
      creatorAvatarUrl: creator?['avatarUrl'] as String?,
      stakeAmountXof: _parseDouble(quest['stakeAmountXof']),
      fundsDistribution: quest['fundsDistribution'] == null
          ? null
          : FundsDistribution.fromJson(quest['fundsDistribution'] as String),
    );
  }

  String get creatorName => [
    creatorFirstName,
    creatorLastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Expected a number or numeric string, got: $value');
  }
}
