String formatResultPercent(num value) {
  final rounded = value.toStringAsFixed(1);
  return '${(rounded.endsWith('.0') ? rounded.substring(0, rounded.length - 2) : rounded).replaceAll('.', ',')} %';
}

class QuestResult {
  QuestResult.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      questId = json['questId'] as String,
      title = json['title'] as String,
      ownerId = json['ownerId'] as String,
      ownerFirstName = json['ownerFirstName'] as String,
      ownerLastName = json['ownerLastName'] as String,
      ownerAvatarUrl = json['ownerAvatarUrl'] as String?,
      status = json['status'] as String,
      reason = json['reason'] as String,
      resolvedAt = DateTime.parse(json['resolvedAt'] as String),
      frequency = json['frequency'] as String,
      successThresholdPercent = json['successThresholdPercent'] as int,
      completedPeriods = json['completedPeriods'] as int,
      expectedPeriods = json['expectedPeriods'] as int,
      completionPercent = (json['completionPercent'] as num).toDouble();

  final String id, questId, title, ownerId, ownerFirstName, ownerLastName;
  final String? ownerAvatarUrl;
  final String status, reason, frequency;
  final DateTime resolvedAt;
  final int successThresholdPercent, completedPeriods, expectedPeriods;
  final double completionPercent;

  bool get isSuccess => status == 'completed';
  bool get isDeletionRejection => reason == 'deletion_rejected';
  String get ownerName =>
      [ownerFirstName, ownerLastName].where((s) => s.isNotEmpty).join(' ');
  String get percentageLabel => formatResultPercent(completionPercent);
  String get periodsLabel =>
      '$completedPeriods / $expectedPeriods ${frequency == 'weekly' ? (expectedPeriods == 1 ? 'semaine' : 'semaines') : (expectedPeriods == 1 ? 'jour' : 'jours')}';
}
