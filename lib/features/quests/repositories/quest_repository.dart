import '../models/quest_model.dart';

class QuestRepository {
  final List<QuestModel> _quests = [
    const QuestModel(
      id: '1',
      title: 'Gym 3x per week',
      durationDays: 30,
      frequency: QuestFrequency.weekly,
      progress: 7,
      total: 12,
      hasStake: true,
    ),
    const QuestModel(
      id: '2',
      title: 'Read 20 minutes daily',
      durationDays: 30,
      frequency: QuestFrequency.daily,
      progress: 12,
      total: 30,
    ),
    const QuestModel(
      id: '3',
      title: 'No social media before 10am',
      durationDays: 21,
      frequency: QuestFrequency.daily,
      progress: 3,
      total: 21,
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
}
