import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'repository_providers.dart';

/// Stream of the active timer entry.
final activeTimerProvider = StreamProvider<TimeEntry?>((ref) {
  final repo = ref.watch(timeTrackingRepositoryProvider);
  return repo.watchActiveTimer();
});

/// Ticks every second when a timer is active, providing elapsed duration.
final timerTickProvider = StreamProvider<Duration>((ref) {
  final activeAsync = ref.watch(activeTimerProvider);
  final activeEntry = activeAsync.valueOrNull;

  if (activeEntry == null) {
    return Stream.value(Duration.zero);
  }

  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateTime.now().difference(activeEntry.startTime);
  });
});

/// Today's total tracked time for the currently active issue.
final todayTotalForActiveIssueProvider = FutureProvider<int>((ref) async {
  final activeAsync = ref.watch(activeTimerProvider);
  final activeEntry = activeAsync.valueOrNull;
  if (activeEntry == null) return 0;

  final repo = ref.watch(timeTrackingRepositoryProvider);
  return repo.timeEntryDao.getTodayTotalForIssue(activeEntry.issueId);
});
