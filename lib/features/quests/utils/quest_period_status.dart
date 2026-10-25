import '../models/check_in_model.dart';
import '../models/quest_model.dart';

enum QuestPeriodStatus { success, missed, inProgress, future }

/// Colors one quest period using the same valid-check-in rule as the backend:
/// a pointage only stops counting if every submitted proof was rejected.
QuestPeriodStatus questPeriodStatus(
  QuestModel quest,
  List<CheckIn> checkIns,
  int period,
  int currentPeriod,
) {
  if (period > currentPeriod) return QuestPeriodStatus.future;
  final utcStart = quest.startDate.toUtc();
  final start = DateTime.utc(utcStart.year, utcStart.month, utcStart.day);
  final spanDays = quest.frequency == QuestFrequency.weekly ? 7 : 1;
  final periodStart = start.add(Duration(days: (period - 1) * spanDays));
  final periodEnd = periodStart.add(Duration(days: spanDays));
  final validCount = checkIns.where((checkIn) {
    final date = checkIn.date.toUtc();
    final day = DateTime.utc(date.year, date.month, date.day);
    return !day.isBefore(periodStart) &&
        day.isBefore(periodEnd) &&
        checkIn.countsTowardTarget;
  }).length;
  if (validCount >= quest.targetPerPeriod) return QuestPeriodStatus.success;
  return period < currentPeriod
      ? QuestPeriodStatus.missed
      : QuestPeriodStatus.inProgress;
}
