import 'quest_ally.dart';

enum QuestFrequency { daily, weekly }

class QuestModel {
  final String id;
  final String title;
  final int durationDays;
  final QuestFrequency frequency;
  final int progress;
  final int total;
  final bool hasStake;
  final String description;
  final double? stakeAmount;
  final bool pendingValidation;
  final String stakeConsequence;
  final List<QuestAlly> allies;
  final List<bool> activityLog;
  final int streakDays;
  final String verificationMethod;
  final String deadline;
  final String gracePeriod;

  const QuestModel({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.frequency,
    required this.progress,
    required this.total,
    this.hasStake = false,
    this.description = '',
    this.stakeAmount,
    this.pendingValidation = false,
    this.stakeConsequence = '',
    this.allies = const [],
    this.activityLog = const [],
    this.streakDays = 0,
    this.verificationMethod = '',
    this.deadline = '',
    this.gracePeriod = '',
  });

  QuestModel copyWith({int? progress}) {
    return QuestModel(
      id: id,
      title: title,
      durationDays: durationDays,
      frequency: frequency,
      progress: progress ?? this.progress,
      total: total,
      hasStake: hasStake,
      description: description,
      stakeAmount: stakeAmount,
      pendingValidation: pendingValidation,
      stakeConsequence: stakeConsequence,
      allies: allies,
      activityLog: activityLog,
      streakDays: streakDays,
      verificationMethod: verificationMethod,
      deadline: deadline,
      gracePeriod: gracePeriod,
    );
  }

  double get progressRatio => total == 0 ? 0 : progress / total;
  bool get isComplete => progress >= total;
}
