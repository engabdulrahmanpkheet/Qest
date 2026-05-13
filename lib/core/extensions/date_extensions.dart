import 'package:intl/intl.dart';

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  int daysUntil(DateTime other) {
    final a = dateOnly;
    final b = other.dateOnly;
    return b.difference(a).inDays;
  }

  String formatShort(String localeCode) =>
      DateFormat.yMMMd(localeCode).format(this);

  String formatTime(String localeCode) =>
      DateFormat.Hm(localeCode).format(this);
}
