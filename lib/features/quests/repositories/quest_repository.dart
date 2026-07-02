import '../models/quest_ally.dart';
import '../models/quest_model.dart';

class QuestRepository {
  final List<QuestModel> _quests = [
    const QuestModel(
      id: '1',
      title: 'Salle de sport 3x/semaine',
      durationDays: 30,
      frequency: QuestFrequency.weekly,
      progress: 7,
      total: 12,
      hasStake: true,
      description: 'La régularité est l\'unique mesure.',
      stakeAmount: 100,
      pendingValidation: true,
      stakeConsequence:
          'Un échec entraînera la perte immédiate au profit de l\'association caritative choisie.',
      allies: [
        QuestAlly(name: 'Marc A.', approved: true),
        QuestAlly(name: 'Léa R.', approved: false),
        QuestAlly(name: 'Jérôme K.', approved: true),
      ],
      activityLog: [
        true, true, false, true, true, true, false,
        true, true, true, true, true, true, true,
        true, true, false, false, false, false, false,
      ],
      streakDays: 12,
      verificationMethod: 'Synchronisation Apple Santé',
      deadline: '23:59 Quotidien',
      gracePeriod: 'Aucune activée',
    ),
    const QuestModel(
      id: '2',
      title: 'Lire 20 minutes par jour',
      durationDays: 30,
      frequency: QuestFrequency.daily,
      progress: 12,
      total: 30,
      hasStake: true,
      description: 'Vingt minutes, sans exception.',
      stakeAmount: 500,
      stakeConsequence: 'Un échec entraînera la perte immédiate de l\'enjeu.',
      allies: [QuestAlly(name: 'Marc A.', approved: true)],
      activityLog: [
        true, true, true, true, false, true, true,
        true, false, true, true, true, false, true,
      ],
      streakDays: 4,
      verificationMethod: 'Déclaration manuelle',
      deadline: '23:59 Quotidien',
      gracePeriod: '1 jour par semaine',
    ),
    const QuestModel(
      id: '3',
      title: 'Pas de réseaux sociaux avant 10h',
      durationDays: 21,
      frequency: QuestFrequency.daily,
      progress: 3,
      total: 21,
      hasStake: true,
      description: 'Protège la première heure.',
      stakeAmount: 250,
      pendingValidation: true,
      stakeConsequence:
          'Un échec entraînera la perte immédiate au profit de l\'association caritative choisie.',
      allies: [
        QuestAlly(name: 'Léa R.', approved: false),
        QuestAlly(name: 'Jérôme K.', approved: false),
      ],
      activityLog: [true, false, true],
      streakDays: 1,
      verificationMethod: 'Rapport d\'écran (Screen Time)',
      deadline: '10:00 Quotidien',
      gracePeriod: 'Aucune activée',
    ),
  ];

  Future<List<QuestModel>> fetchQuests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_quests);
  }

  Future<QuestModel> checkIn(String questId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) throw Exception('Quest not found');
    final updated = _quests[index].copyWith(
      progress: (_quests[index].progress + 1).clamp(0, _quests[index].total),
    );
    _quests[index] = updated;
    return updated;
  }

  Future<QuestModel> createQuest(QuestModel quest) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _quests.add(quest);
    return quest;
  }
}
