extension DateTimeHelpers on DateTime {
  /// Get the start of this day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get Monday of this week.
  DateTime get startOfWeek {
    final daysFromMonday = weekday - DateTime.monday;
    return DateTime(year, month, day - daysFromMonday);
  }

  /// Get the first day of this month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Get the first day of next month.
  DateTime get startOfNextMonth => DateTime(year, month + 1);

  /// Check if same day as another date.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Check if same week as another date.
  bool isSameWeek(DateTime other) =>
      startOfWeek.isSameDay(other.startOfWeek);
}
