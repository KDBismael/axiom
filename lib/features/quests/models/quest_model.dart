enum QuestFrequency {
  daily,
  weekly;

  factory QuestFrequency.fromJson(String value) =>
      QuestFrequency.values.firstWhere((v) => v.name == value);

  String toJson() => name;
}

enum QuestRiskLevel {
  low,
  medium,
  high;

  factory QuestRiskLevel.fromJson(String value) =>
      QuestRiskLevel.values.firstWhere((v) => v.name == value);

  String toJson() => name;
}

enum FundsDistribution {
  allies,
  charity;

  factory FundsDistribution.fromJson(String value) =>
      FundsDistribution.values.firstWhere((v) => v.name == value);

  String toJson() => name;
}

enum QuestStatus {
  pendingPayment,
  active,
  completed,
  failed,
  cancelled;

  factory QuestStatus.fromJson(String value) {
    switch (value) {
      case 'pending_payment':
        return QuestStatus.pendingPayment;
      case 'active':
        return QuestStatus.active;
      case 'completed':
        return QuestStatus.completed;
      case 'failed':
        return QuestStatus.failed;
      case 'cancelled':
        return QuestStatus.cancelled;
    }
    throw ArgumentError('Unknown quest status: $value');
  }
}

enum QuestAllyStatus {
  pending,
  accepted,
  declined;

  factory QuestAllyStatus.fromJson(String value) =>
      QuestAllyStatus.values.firstWhere((v) => v.name == value);

  String toJson() => name;
}

/// A friend invited as a specific quest's accountability partner — distinct
/// from the global ally/friend relationship (see `Ally`).
class QuestAllyRef {
  const QuestAllyRef({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.avatarUrl,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final QuestAllyStatus status;

  factory QuestAllyRef.fromJson(Map<String, dynamic> json) {
    return QuestAllyRef(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: QuestAllyStatus.fromJson(json['status'] as String),
    );
  }
}

class QuestModel {
  const QuestModel({
    required this.id,
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
    required this.hasStake,
    required this.status,
    required this.progress,
    required this.streakDays,
    this.stakeAmountXof,
    this.fundsDistribution,
    this.allies = const [],
  });

  final String id;
  final String title;
  final String description;
  final QuestFrequency frequency;
  final int durationDays;

  /// Check-ins required per period (day for daily, ISO week for weekly) for
  /// that period to count toward the streak/progress. 1 for every quest
  /// created before this field existed.
  final int targetPerPeriod;
  final DateTime startDate;
  final DateTime deadline;
  final int gracePeriodDays;
  final QuestRiskLevel riskLevel;
  final bool requiresProof;
  final int successThresholdPercent;
  final bool hasStake;
  final double? stakeAmountXof;
  final FundsDistribution? fundsDistribution;
  final QuestStatus status;

  /// Server-computed, 0–1.
  final double progress;

  /// Server-computed/cached.
  final int streakDays;

  /// Only populated by `GET /quests/:id` — the list endpoint omits it.
  final List<QuestAllyRef> allies;

  bool get isPendingPayment => status == QuestStatus.pendingPayment;
  bool get isActive => status == QuestStatus.active;

  /// Completed, failed, or cancelled — a terminal state shown in History.
  bool get isFinished =>
      status == QuestStatus.completed ||
      status == QuestStatus.failed ||
      status == QuestStatus.cancelled;

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: QuestFrequency.fromJson(json['frequency'] as String),
      durationDays: json['durationDays'] as int,
      targetPerPeriod: json['targetPerPeriod'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      gracePeriodDays: json['gracePeriodDays'] as int,
      riskLevel: QuestRiskLevel.fromJson(json['riskLevel'] as String),
      requiresProof: json['requiresProof'] as bool,
      successThresholdPercent: json['successThresholdPercent'] as int,
      hasStake: json['hasStake'] as bool,
      stakeAmountXof: _parseDouble(json['stakeAmountXof']),
      fundsDistribution: json['fundsDistribution'] == null
          ? null
          : FundsDistribution.fromJson(json['fundsDistribution'] as String),
      status: QuestStatus.fromJson(json['status'] as String),
      progress: _parseDouble(json['progress']) ?? 0,
      streakDays: json['streakDays'] as int,
      allies: json['allies'] == null
          ? const []
          : (json['allies'] as List)
              .map((a) => QuestAllyRef.fromJson(a as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Prisma serializes `Decimal` fields (like `stakeAmountXof`) as JSON
  /// strings, not numbers — this accepts either.
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Expected a number or numeric string, got: $value');
  }

  QuestModel copyWith({double? progress, int? streakDays}) {
    return QuestModel(
      id: id,
      title: title,
      description: description,
      frequency: frequency,
      durationDays: durationDays,
      targetPerPeriod: targetPerPeriod,
      startDate: startDate,
      deadline: deadline,
      gracePeriodDays: gracePeriodDays,
      riskLevel: riskLevel,
      requiresProof: requiresProof,
      successThresholdPercent: successThresholdPercent,
      hasStake: hasStake,
      stakeAmountXof: stakeAmountXof,
      fundsDistribution: fundsDistribution,
      status: status,
      progress: progress ?? this.progress,
      streakDays: streakDays ?? this.streakDays,
      allies: allies,
    );
  }
}
