extension DurationFormatting on Duration {
  /// Format as "HH:MM:SS".
  String toHms() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Format as decimal hours, e.g. "1.5h".
  String toDecimalHours() {
    final hours = inSeconds / 3600;
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Format as human-readable, e.g. "3h 45m".
  String toHumanReadable() {
    if (inSeconds < 60) return '${inSeconds}s';
    if (inMinutes < 60) return '${inMinutes}m';
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

extension IntDurationExtension on int {
  /// Convert seconds to formatted duration string.
  String toFormattedDuration({String format = 'hms'}) {
    final d = Duration(seconds: this);
    return format == 'decimal' ? d.toDecimalHours() : d.toHms();
  }
}
