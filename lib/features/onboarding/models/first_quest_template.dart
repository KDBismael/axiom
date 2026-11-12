import '../../quests/models/quest_model.dart';

/// A ready-made first quest offered by the guided tour: solo, no stake, no
/// proof — the lightest possible commitment for day one.
class FirstQuestTemplate {
  const FirstQuestTemplate({
    required this.emoji,
    required this.title,
    required this.description,
    required this.frequency,
    required this.durationDays,
    this.targetPerPeriod = 1,
  });

  final String emoji;
  final String title;
  final String description;
  final QuestFrequency frequency;
  final int durationDays;
  final int targetPerPeriod;

  /// "Chaque jour · 30 jours", "3× par semaine · 4 semaines".
  String get summary => frequency == QuestFrequency.weekly
      ? '$targetPerPeriod× par semaine · ${durationDays ~/ 7} semaines'
      : 'Chaque jour · $durationDays jours';

  /// Same shape as the payload `QuestCreateController.submit` sends.
  Map<String, dynamic> toPayload(DateTime now) => {
    'title': title,
    'description': description,
    'frequency': frequency.toJson(),
    'durationDays': durationDays,
    'targetPerPeriod': targetPerPeriod,
    'startDate': now.toIso8601String(),
    'deadline': now.add(Duration(days: durationDays)).toIso8601String(),
    'gracePeriodDays': 0,
    'riskLevel': QuestRiskLevel.low.toJson(),
    'requiresProof': false,
    'successThresholdPercent': 80,
    'hasStake': false,
  };
}

const firstQuestTemplates = [
  FirstQuestTemplate(
    emoji: '🧘',
    title: 'Méditer 10 minutes',
    description: 'Dix minutes de calme chaque jour pour me recentrer.',
    frequency: QuestFrequency.daily,
    durationDays: 30,
  ),
  FirstQuestTemplate(
    emoji: '🏋️',
    title: 'Sport 3×/semaine',
    description: 'Trois séances par semaine pour reprendre le rythme.',
    frequency: QuestFrequency.weekly,
    durationDays: 28,
    targetPerPeriod: 3,
  ),
  FirstQuestTemplate(
    emoji: '📖',
    title: 'Lire 10 pages',
    description: 'Dix pages par jour, un livre par mois.',
    frequency: QuestFrequency.daily,
    durationDays: 30,
  ),
  FirstQuestTemplate(
    emoji: '🚶',
    title: 'Marcher 30 minutes',
    description: 'Une marche de trente minutes chaque jour.',
    frequency: QuestFrequency.daily,
    durationDays: 30,
  ),
];
