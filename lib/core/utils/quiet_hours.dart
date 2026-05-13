import '../constants/app_constants.dart';

/// Returns the next allowed wall-clock time given quiet-hours window.
/// Quiet hours are [22:00, 10:00). Anything inside that window is shifted
/// forward to 10:00 of the appropriate day.
DateTime clampToActiveHours(DateTime when) {
  final start = AppConstants.quietHoursStart; // 22
  final end = AppConstants.quietHoursEnd; // 10

  final hour = when.hour;
  final inQuiet = hour >= start || hour < end;
  if (!inQuiet) return when;

  // If late evening (>= 22), bump to 10am next day.
  if (hour >= start) {
    final next = when.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, end);
  }
  // If early morning (< 10), bump to 10am same day.
  return DateTime(when.year, when.month, when.day, end);
}

/// Distributes [count] reminder times evenly across the active window
/// (10:00–22:00) for [date].
List<DateTime> spreadReminderSlots(DateTime date, int count) {
  final start = AppConstants.quietHoursEnd; // 10
  final end = AppConstants.quietHoursStart; // 22
  final span = end - start; // 12h
  final step = span ~/ (count + 1);
  return List<DateTime>.generate(count, (i) {
    final hour = start + step * (i + 1);
    return DateTime(date.year, date.month, date.day, hour);
  });
}
