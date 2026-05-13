enum RecurringType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  DateTime nextOccurrence(DateTime from) {
    switch (this) {
      case RecurringType.none:
        return from;
      case RecurringType.daily:
        return from.add(const Duration(days: 1));
      case RecurringType.weekly:
        return from.add(const Duration(days: 7));
      case RecurringType.monthly:
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      case RecurringType.yearly:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    }
  }
}
