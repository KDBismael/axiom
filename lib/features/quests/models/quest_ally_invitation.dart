import 'quest_model.dart';

/// Full terms of a quest a friend was invited to ally on — shown before they
/// accept/decline, since accepting means proof-validation duty, a deletion
/// vote, and a potential payout share on failure. `GET
/// /quests/:id/ally-invitation`.
class QuestAllyInvitation {
  const QuestAllyInvitation({
    required this.status,
    required this.questId,
    required this.title,
    required this.description,
    required this.frequency,
    required this.durationDays,
    required this.startDate,
    required this.deadline,
    required this.hasStake,
    this.stakeAmountXof,
    this.fundsDistribution,
  });

  final QuestAllyStatus status;
  final String questId;
  final String title;
  final String description;
  final QuestFrequency frequency;
  final int durationDays;
  final DateTime startDate;
  final DateTime deadline;
  final bool hasStake;
  final double? stakeAmountXof;
  final FundsDistribution? fundsDistribution;

  factory QuestAllyInvitation.fromJson(Map<String, dynamic> json) {
    final invitation = json['invitation'] as Map<String, dynamic>;
    final quest = json['quest'] as Map<String, dynamic>;
    return QuestAllyInvitation(
      status: QuestAllyStatus.fromJson(invitation['status'] as String),
      questId: quest['id'] as String,
      title: quest['title'] as String,
      description: quest['description'] as String,
      frequency: QuestFrequency.fromJson(quest['frequency'] as String),
      durationDays: quest['durationDays'] as int,
      startDate: DateTime.parse(quest['startDate'] as String),
      deadline: DateTime.parse(quest['deadline'] as String),
      hasStake: quest['hasStake'] as bool,
      stakeAmountXof: _parseDouble(quest['stakeAmountXof']),
      fundsDistribution: quest['fundsDistribution'] == null
          ? null
          : FundsDistribution.fromJson(quest['fundsDistribution'] as String),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Expected a number or numeric string, got: $value');
  }
}
