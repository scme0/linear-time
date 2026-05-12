import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/time_entry_dao.dart';
import '../../core/constants.dart';

class TimeTrackingRepository {
  TimeTrackingRepository({required this.timeEntryDao, required this.settingsDao});

  final TimeEntryDao timeEntryDao;
  final dynamic settingsDao;

  /// Start a timer on an issue. Stops any active timer first.
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
  /// Auto-splits at midnight boundaries.
  Future<void> stopTimer() async {
    final active = await timeEntryDao.getActiveEntry();
    if (active == null) return;

    await timeEntryDao.stopEntry(active.id);
    await timeEntryDao.finalizeDuration(active.id);

    // Check minimum duration
    final minSeconds = await _getMinDurationSeconds();
    final stoppedEntries = await timeEntryDao.getEntriesForDay(DateTime.now());
    final stopped = stoppedEntries.where((e) => e.id == active.id).firstOrNull;
    if (stopped != null &&
        stopped.durationSeconds != null &&
        stopped.durationSeconds! < minSeconds) {
      await timeEntryDao.deleteEntry(active.id);
      return;
    }

    // Finalize the entry (midnight split)
    if (stopped != null && stopped.endTime != null) {
      await _finalizeEntry(stopped);
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
  /// Auto-splits at midnight boundaries.
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

    // Finalize (midnight split)
    final entries = await timeEntryDao.getEntriesForDay(startTime);
    final entry = entries.where((e) => e.id == id).firstOrNull;
    if (entry != null) {
      await _finalizeEntry(entry);
    }

    return id;
  }

  // ── Private ──────────────────────────────────────────────────────

  /// Finalize a completed entry: split at midnight boundaries if needed.
  Future<void> _finalizeEntry(TimeEntry entry) async {
    if (entry.endTime == null) return;
    await _splitAtMidnights(entry);
  }

  /// Split a completed entry at each midnight boundary.
  Future<void> _splitAtMidnights(TimeEntry entry) async {
    final start = entry.startTime;
    final end = entry.endTime!;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    if (startDay == endDay) return;

    // Trim original entry to first midnight
    final firstMidnight = startDay.add(const Duration(days: 1));
    await timeEntryDao.updateEntry(
      entry.id,
      TimeEntriesCompanion(
        endTime: Value(firstMidnight),
        durationSeconds: Value(firstMidnight.difference(start).inSeconds),
      ),
    );

    // Create entries for each subsequent day
    var currentStart = firstMidnight;
    var currentDay = firstMidnight;

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
      currentDay = nextMidnight;
    }
  }

  Future<int> _getMinDurationSeconds() async {
    final val = await settingsDao.getValue(SettingsKeys.minEntryDurationSeconds);
    if (val != null) return int.tryParse(val) ?? kDefaultMinEntryDurationSeconds;
    return kDefaultMinEntryDurationSeconds;
  }
}
