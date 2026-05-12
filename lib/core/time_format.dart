/// Global time format setting, updated from AppSettings.
class TimeFormat {
  static String current = 'human';

  /// Suggested column width for displaying formatted durations.
  static double get columnWidth => switch (current) {
        'hms' => 72,
        'decimal' => 45,
        _ => 50, // human
      };
}
