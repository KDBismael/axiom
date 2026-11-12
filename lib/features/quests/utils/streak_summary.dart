import '../models/quest_model.dart';

/// `streakDays` counts periods: days for a daily quest, ISO weeks for a
/// weekly one. This is the unit to display next to it.
String streakUnit(QuestFrequency frequency, int count) {
  final plural = count > 1;
  return frequency == QuestFrequency.weekly
      ? (plural ? 'semaines' : 'semaine')
      : (plural ? 'jours' : 'jour');
}

class StreakSummary {
  const StreakSummary(this.count, this.frequency);

  final int count;
  final QuestFrequency frequency;

  String get label => '${streakUnit(frequency, count)} sans rupture';
}

/// The longest current streak across [quests], compared by elapsed time
/// (a week counts as 7 days) but reported in its own quest's unit — so a
/// 3-week streak beats a 5-day one and still reads "3 semaines".
StreakSummary bestStreak(Iterable<QuestModel> quests) {
  var best = const StreakSummary(0, QuestFrequency.daily);
  var bestDays = 0;
  for (final quest in quests) {
    final days = quest.frequency == QuestFrequency.weekly
        ? quest.streakDays * 7
        : quest.streakDays;
    if (days > bestDays) {
      bestDays = days;
      best = StreakSummary(quest.streakDays, quest.frequency);
    }
  }
  return best;
}
