import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/time_entries.dart';

part 'time_entry_dao.g.dart';

@DriftAccessor(tables: [TimeEntries])
class TimeEntryDao extends DatabaseAccessor<AppDatabase>
    with _$TimeEntryDaoMixin {
  TimeEntryDao(super.db);

  /// Get the currently running entry (endTime is null).
  Future<TimeEntry?> getActiveEntry() {
    return (select(timeEntries)..where((t) => t.endTime.isNull()))
        .getSingleOrNull();
  }

  /// Watch the currently running entry.
  Stream<TimeEntry?> watchActiveEntry() {
    return (select(timeEntries)..where((t) => t.endTime.isNull()))
        .watchSingleOrNull();
  }

  /// Start a new time entry. Returns the inserted entry's id.
  Future<int> startEntry({
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    String? teamName,
    String? projectName,
    String? teamColor,
  }) {
    return into(timeEntries).insert(TimeEntriesCompanion.insert(
      issueId: issueId,
      issueIdentifier: issueIdentifier,
      issueTitle: issueTitle,
      teamName: Value(teamName),
      projectName: Value(projectName),
      teamColor: Value(teamColor),
      startTime: DateTime.now(),
    ));
  }

  /// Stop the active entry by setting endTime and computing duration.
  Future<int> stopEntry(int id) {
    final now = DateTime.now();
    return (update(timeEntries)..where((t) => t.id.equals(id))).write(
      TimeEntriesCompanion(
        endTime: Value(now),
      ),
    );
  }

  /// After stopping, compute and store duration.
  Future<void> finalizeDuration(int id) async {
    final entry = await (select(timeEntries)..where((t) => t.id.equals(id)))
        .getSingle();
    if (entry.endTime != null) {
      final duration = entry.endTime!.difference(entry.startTime).inSeconds;
      await (update(timeEntries)..where((t) => t.id.equals(id))).write(
        TimeEntriesCompanion(durationSeconds: Value(duration)),
      );
    }
  }

  /// Add a manual time entry.
  Future<int> addManualEntry({
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    String? teamName,
    String? projectName,
    String? teamColor,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final duration = endTime.difference(startTime).inSeconds;
    return into(timeEntries).insert(TimeEntriesCompanion.insert(
      issueId: issueId,
      issueIdentifier: issueIdentifier,
      issueTitle: issueTitle,
      teamName: Value(teamName),
      projectName: Value(projectName),
      teamColor: Value(teamColor),
      startTime: startTime,
      endTime: Value(endTime),
      durationSeconds: Value(duration),
      isManual: Value(true),
    ));
  }

  /// Check for overlapping entries in a time range.
  Future<List<TimeEntry>> getOverlappingEntries(
    DateTime start,
    DateTime end, {
    int? excludeId,
  }) {
    final query = select(timeEntries)
      ..where((t) {
        final overlaps = t.startTime.isSmallerThanValue(end) &
            (t.endTime.isNull() | t.endTime.isBiggerThanValue(start));
        if (excludeId != null) {
          return overlaps & t.id.equals(excludeId).not();
        }
        return overlaps;
      });
    return query.get();
  }

  /// Get all entries for a specific day.
  Future<List<TimeEntry>> getEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(timeEntries)
          ..where(
              (t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Get all entries for a week (Monday start).
  Future<List<TimeEntry>> getEntriesForWeek(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return (select(timeEntries)
          ..where((t) =>
              t.startTime.isBiggerOrEqualValue(weekStart) &
              t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Get all entries for a month.
  Future<List<TimeEntry>> getEntriesForMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(timeEntries)
          ..where((t) =>
              t.startTime.isBiggerOrEqualValue(start) &
              t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Get the last N distinct issues that had time tracked.
  Future<List<TimeEntry>> getRecentTrackedIssues({int limit = 5}) async {
    final rows = await customSelect(
      'SELECT * FROM time_entries WHERE id IN ('
      '  SELECT MAX(id) FROM time_entries GROUP BY issue_id ORDER BY MAX(start_time) DESC LIMIT ?'
      ')',
      variables: [Variable.withInt(limit)],
      readsFrom: {timeEntries},
    ).get();
    return rows.map((row) => timeEntries.map(row.data)).toList();
  }

  /// Delete an entry.
  Future<int> deleteEntry(int id) {
    return (delete(timeEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all entries.
  Future<int> deleteAll() {
    return delete(timeEntries).go();
  }

  /// Get all entries (for export).
  Future<List<TimeEntry>> getAllEntries() {
    return (select(timeEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Update an entry (for manual corrections).
  Future<int> updateEntry(int id, TimeEntriesCompanion companion) {
    return (update(timeEntries)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Get today's total seconds for a specific issue.
  Future<int> getTodayTotalForIssue(String issueId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final result = await customSelect(
      'SELECT COALESCE(SUM(duration_seconds), 0) as total FROM time_entries '
      'WHERE issue_id = ? AND start_time >= ? AND start_time < ? AND end_time IS NOT NULL',
      variables: [
        Variable.withString(issueId),
        Variable.withDateTime(today),
        Variable.withDateTime(tomorrow),
      ],
      readsFrom: {timeEntries},
    ).getSingle();
    return result.data['total'] as int;
  }
}
