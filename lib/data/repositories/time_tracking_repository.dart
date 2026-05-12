import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/time_entry_dao.dart';
import '../../core/constants.dart';

class TimeTrackingRepository {
  TimeTrackingRepository({required this.timeEntryDao, required this.settingsDao});

  final TimeEntryDao timeEntryDao;
  final dynamic settingsDao; // SettingsDao, using dynamic to avoid circular

  /// Start a timer on an issue. Stops any active timer first.
  /// Returns the new entry ID, or null if the entry was too short (discarded).
  Future<int> startTimer({
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    String? teamName,
    String? projectName,
    String? teamColor,
  }) async {
    await stopTimer();
    return timeEntryDao.startEntry(
      issueId: issueId,
      issueIdentifier: issueIdentifier,
      issueTitle: issueTitle,
      teamName: teamName,
      projectName: projectName,
      teamColor: teamColor,
    );
  }

  /// Stop the current timer. Discards if below minimum duration.
  Future<void> stopTimer() async {
    final active = await timeEntryDao.getActiveEntry();
    if (active == null) return;

    await timeEntryDao.stopEntry(active.id);
    await timeEntryDao.finalizeDuration(active.id);

    // Check minimum duration — discard if too short
    final minSeconds = await _getMinDurationSeconds();
    final stoppedEntries = await timeEntryDao.getEntriesForDay(DateTime.now());
    final stopped = stoppedEntries.where((e) => e.id == active.id).firstOrNull;
    if (stopped != null &&
        stopped.durationSeconds != null &&
        stopped.durationSeconds! < minSeconds) {
      await timeEntryDao.deleteEntry(active.id);
      return;
    }

    // Split at midnight if entry spans multiple days
    if (stopped != null && stopped.endTime != null) {
      await _splitAtMidnights(stopped);
    }
  }

  /// Split a completed entry at each midnight boundary.
  Future<void> _splitAtMidnights(TimeEntry entry) async {
    final start = entry.startTime;
    final end = entry.endTime!;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    // Same day — nothing to split
    if (startDay == endDay) return;

    // Walk through each midnight boundary
    var currentStart = start;
    var currentDay = startDay;

    // Update the original entry to end at first midnight
    final firstMidnight = currentDay.add(const Duration(days: 1));
    await timeEntryDao.updateEntry(
      entry.id,
      TimeEntriesCompanion(
        endTime: Value(firstMidnight),
        durationSeconds: Value(firstMidnight.difference(start).inSeconds),
      ),
    );

    currentStart = firstMidnight;
    currentDay = currentDay.add(const Duration(days: 1));

    // Create new entries for each subsequent day
    while (currentDay.isBefore(endDay) || currentDay == endDay) {
      final nextMidnight = currentDay.add(const Duration(days: 1));
      final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;

      if (segmentEnd.difference(currentStart).inSeconds > 0) {
        await timeEntryDao.addManualEntry(
          issueId: entry.issueId,
          issueIdentifier: entry.issueIdentifier,
          issueTitle: entry.issueTitle,
          teamName: entry.teamName,
          projectName: entry.projectName,
          teamColor: entry.teamColor,
          startTime: currentStart,
          endTime: segmentEnd,
        );
      }

      if (!nextMidnight.isBefore(end)) break;
      currentStart = nextMidnight;
      currentDay = currentDay.add(const Duration(days: 1));
    }
  }

  /// Switch timer to a new issue (atomic stop + start).
  Future<int> switchTimer({
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    String? teamName,
    String? projectName,
    String? teamColor,
  }) {
    return startTimer(
      issueId: issueId,
      issueIdentifier: issueIdentifier,
      issueTitle: issueTitle,
      teamName: teamName,
      projectName: projectName,
      teamColor: teamColor,
    );
  }

  /// Get the currently active timer entry.
  Future<TimeEntry?> getActiveTimer() => timeEntryDao.getActiveEntry();

  /// Watch the active timer.
  Stream<TimeEntry?> watchActiveTimer() => timeEntryDao.watchActiveEntry();

  /// Add a manual time entry. Returns null if overlapping.
  Future<int?> addManualEntry({
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    String? teamName,
    String? projectName,
    String? teamColor,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final overlaps =
        await timeEntryDao.getOverlappingEntries(startTime, endTime);
    if (overlaps.isNotEmpty) return null;

    final id = await timeEntryDao.addManualEntry(
      issueId: issueId,
      issueIdentifier: issueIdentifier,
      issueTitle: issueTitle,
      teamName: teamName,
      projectName: projectName,
      teamColor: teamColor,
      startTime: startTime,
      endTime: endTime,
    );

    // Split at midnights if spanning multiple days
    final entries = await timeEntryDao.getEntriesForDay(startTime);
    final entry = entries.where((e) => e.id == id).firstOrNull;
    if (entry != null) {
      await _splitAtMidnights(entry);
    }

    return id;
  }

  /// Split an entry at midnight if it spans multiple days.
  Future<void> splitMidnightEntries() async {
    final active = await timeEntryDao.getActiveEntry();
    if (active == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (active.startTime.isBefore(today)) {
      // Stop the old entry at midnight
      await timeEntryDao.updateEntry(
        active.id,
        TimeEntriesCompanion(
          endTime: Value(today),
          durationSeconds:
              Value(today.difference(active.startTime).inSeconds),
        ),
      );

      // Start a new entry from midnight
      await timeEntryDao.startEntry(
        issueId: active.issueId,
        issueIdentifier: active.issueIdentifier,
        issueTitle: active.issueTitle,
        teamName: active.teamName,
        projectName: active.projectName,
        teamColor: active.teamColor,
      );

      // Update the new entry's start time to midnight
      final newActive = await timeEntryDao.getActiveEntry();
      if (newActive != null) {
        await timeEntryDao.updateEntry(
          newActive.id,
          TimeEntriesCompanion(startTime: Value(today)),
        );
      }
    }
  }

  Future<int> _getMinDurationSeconds() async {
    final val = await settingsDao.getValue(SettingsKeys.minEntryDurationSeconds);
    if (val != null) return int.tryParse(val) ?? kDefaultMinEntryDurationSeconds;
    return kDefaultMinEntryDurationSeconds;
  }
}
