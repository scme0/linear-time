import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_providers.dart';

/// Provider family for entries in a given month.
final monthlyEntriesProvider =
    FutureProvider.family<List<TimeEntry>, DateTime>((ref, month) async {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.getEntriesForMonth(month.year, month.month);
});

/// Provider family for entries in a given week (pass Monday date).
final weeklyEntriesProvider =
    FutureProvider.family<List<TimeEntry>, DateTime>((ref, weekStart) async {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.getEntriesForWeek(weekStart);
});

/// Provider family for entries on a given day.
final dailyEntriesProvider =
    FutureProvider.family<List<TimeEntry>, DateTime>((ref, day) async {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.getEntriesForDay(day);
});

/// Aggregate monthly data: per-day totals with project breakdown.
final monthlyCalendarDataProvider =
    FutureProvider.family<Map<int, DayData>, DateTime>((ref, month) async {
  final entries = await ref.watch(monthlyEntriesProvider(month).future);
  final dayMap = <int, DayData>{};

  for (final entry in entries) {
    if (entry.endTime == null) continue;
    final day = entry.startTime.day;
    final data = dayMap.putIfAbsent(day, () => DayData());
    final seconds = entry.durationSeconds ??
        entry.endTime!.difference(entry.startTime).inSeconds;
    data.totalSeconds += seconds;
    final key = entry.projectName ?? entry.teamName ?? 'Other';
    data.projectSeconds[key] = (data.projectSeconds[key] ?? 0) + seconds;
    if (entry.teamColor != null) {
      data.projectColors[key] = entry.teamColor!;
    }
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
    if (entry.endTime == null) continue;
    final seconds = entry.durationSeconds ??
        entry.endTime!.difference(entry.startTime).inSeconds;
    grandTotal += seconds;

    final summary = issueMap.putIfAbsent(
      entry.issueId,
      () => IssueSummary(
        issueId: entry.issueId,
        identifier: entry.issueIdentifier,
        title: entry.issueTitle,
        teamName: entry.teamName,
        teamColor: entry.teamColor,
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
  final Map<String, int> projectSeconds = {};
  final Map<String, String> projectColors = {};
}

class IssueSummary {
  IssueSummary({
    required this.issueId,
    required this.identifier,
    required this.title,
    this.teamName,
    this.teamColor,
    this.projectName,
  });

  final String issueId;
  final String identifier;
  final String title;
  final String? teamName;
  final String? teamColor;
  final String? projectName;
  int totalSeconds = 0;
  int entryCount = 0;
}

class WeeklySummary {
  const WeeklySummary({required this.issues, required this.grandTotalSeconds});
  final List<IssueSummary> issues;
  final int grandTotalSeconds;
}
