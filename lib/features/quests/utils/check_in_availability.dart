import '../models/check_in_model.dart';
import '../models/quest_model.dart';
import 'period_progress.dart';

enum CheckInAvailability { available, periodComplete, deadlinePassed, inactive }

/// Client-side preview of the backend check-in rules. The API remains the
/// authority when a check-in is submitted.
CheckInAvailability checkInAvailability(
  QuestModel quest,
  List<CheckIn> checkIns,
  DateTime now,
) {
  if (!quest.isActive) return CheckInAvailability.inactive;
  final todayUtc = now.toUtc();
  final deadlineUtc = quest.deadline.toUtc();
  final today = DateTime.utc(todayUtc.year, todayUtc.month, todayUtc.day);
  final lastAllowed = DateTime.utc(
    deadlineUtc.year,
    deadlineUtc.month,
    deadlineUtc.day + quest.gracePeriodDays,
  );
  if (today.isAfter(lastAllowed)) {
    return CheckInAvailability.deadlinePassed;
  }
  final count = countCheckInsInCurrentPeriod(
    checkIns,
    quest.frequency,
    now,
    startDate: quest.startDate,
  );
  return count >= quest.targetPerPeriod
      ? CheckInAvailability.periodComplete
      : CheckInAvailability.available;
}
