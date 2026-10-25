import '../models/check_in_model.dart';
import '../models/quest_model.dart';

DateTime _utcDay(DateTime date) {
  final utc = date.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

/// Counts check-ins in today's period, ignoring fully rejected ones so the
/// user can submit again while the period is still open. Weekly periods are seven-day windows
/// anchored to the quest start date, matching the backend's periodRange.
int countCheckInsInCurrentPeriod(
  List<CheckIn> checkIns,
  QuestFrequency frequency,
  DateTime now, {
  required DateTime startDate,
}) {
  final today = _utcDay(now);
  final start = _utcDay(startDate);
  if (today.isBefore(start)) return 0;
  final periodStart = frequency == QuestFrequency.daily
      ? today
      : start.add(Duration(days: today.difference(start).inDays ~/ 7 * 7));
  final periodEnd = periodStart.add(
    Duration(days: frequency == QuestFrequency.daily ? 1 : 7),
  );
  return checkIns.where((c) {
    final day = _utcDay(c.date);
    return !day.isBefore(periodStart) &&
        day.isBefore(periodEnd) &&
        c.countsTowardTarget;
  }).length;
}
