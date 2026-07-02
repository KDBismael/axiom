enum QuestFrequency { daily, weekly }

class QuestModel {
  final String id;
  final String title;
  final int durationDays;
  final QuestFrequency frequency;
  final int progress;
  final int total;
  final bool hasStake;

  const QuestModel({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.frequency,
    required this.progress,
    required this.total,
    this.hasStake = false,
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
    );
  }

  double get progressRatio => total == 0 ? 0 : progress / total;
  bool get isComplete => progress >= total;
}
