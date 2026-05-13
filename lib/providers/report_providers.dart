import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_providers.dart';

/// Provider family for entries in a given month (reactive).
final monthlyEntriesProvider =
    StreamProvider.family<List<TimeEntry>, DateTime>((ref, month) {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.watchEntriesForMonth(month.year, month.month);
});

/// Provider family for entries in a given week (pass Monday date, reactive).
final weeklyEntriesProvider =
    StreamProvider.family<List<TimeEntry>, DateTime>((ref, weekStart) {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.watchEntriesForWeek(weekStart);
});

/// Provider family for entries on a given day (reactive).
final dailyEntriesProvider =
    StreamProvider.family<List<TimeEntry>, DateTime>((ref, day) {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.watchEntriesForDay(day);
});

/// Aggregate monthly data: per-day totals with issue breakdown.
/// Keyed by issueId for consistent colors via AppColors.colorForIssue().
final monthlyCalendarDataProvider =
    FutureProvider.family<Map<int, DayData>, DateTime>((ref, month) async {
  final entries = await ref.watch(monthlyEntriesProvider(month).future);
  final dayMap = <int, DayData>{};

  for (final entry in entries) {
    final day = entry.startTime.day;
    final data = dayMap.putIfAbsent(day, () => DayData());
    final seconds = entry.durationSeconds ??
        (entry.endTime ?? DateTime.now()).difference(entry.startTime).inSeconds;
    data.totalSeconds += seconds;

    // Key by issueId for consistent color assignment
    data.issueSeconds[entry.issueId] =
        (data.issueSeconds[entry.issueId] ?? 0) + seconds;
    data.issueLabels[entry.issueId] = entry.issueIdentifier;
  }

  return dayMap;
});

/// Weekly summary: grouped by issue with totals.
final weeklySummaryProvider =
    FutureProvider.family<WeeklySummary, DateTime>((ref, weekStart) async {
  final entries = await ref.watch(weeklyEntriesProvider(weekStart).future);
  final issueMap = <String, IssueSummary>{};
  int grandTotal = 0;

  for (final entry in entries) {
    final seconds = entry.durationSeconds ??
        (entry.endTime ?? DateTime.now()).difference(entry.startTime).inSeconds;
    grandTotal += seconds;

    final summary = issueMap.putIfAbsent(
      entry.issueId,
      () => IssueSummary(
        issueId: entry.issueId,
        identifier: entry.issueIdentifier,
        title: entry.issueTitle,
        teamName: entry.teamName,
        projectName: entry.projectName,
      ),
    );
    summary.totalSeconds += seconds;
    summary.entryCount++;
  }

  final issues = issueMap.values.toList()
    ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

  return WeeklySummary(issues: issues, grandTotalSeconds: grandTotal);
});

class DayData {
  int totalSeconds = 0;
  /// Keyed by issueId — use AppColors.colorForIssue(issueId) for color.
  final Map<String, int> issueSeconds = {};
  /// issueId -> identifier label (e.g. "ENG-123") for tooltips.
  final Map<String, String> issueLabels = {};
}

class IssueSummary {
  IssueSummary({
    required this.issueId,
    required this.identifier,
    required this.title,
    this.teamName,
    this.projectName,
  });

  final String issueId;
  final String identifier;
  final String title;
  final String? teamName;
  final String? projectName;
  int totalSeconds = 0;
  int entryCount = 0;
}

class WeeklySummary {
  const WeeklySummary({required this.issues, required this.grandTotalSeconds});
  final List<IssueSummary> issues;
  final int grandTotalSeconds;
}
