import '../models/check_in_model.dart';
import '../models/quest_model.dart';

/// Returns the ISO week number of [date] (Mon=start), used to bucket weekly
/// quests the same way the backend does.
int isoWeek(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

/// How many of [checkIns] fall in the period (day for daily, ISO week for
/// weekly) that [now] is currently in — the same bucketing the backend's
/// streak/progress logic uses server-side.
int countCheckInsInCurrentPeriod(
  List<CheckIn> checkIns,
  QuestFrequency frequency,
  DateTime now,
) {
  return checkIns.where((c) {
    if (frequency == QuestFrequency.daily) {
      return c.date.year == now.year &&
          c.date.month == now.month &&
          c.date.day == now.day;
    }
    return isoWeek(c.date) == isoWeek(now) && c.date.year == now.year;
  }).length;
}
