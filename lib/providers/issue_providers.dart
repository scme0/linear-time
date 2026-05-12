import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// Assigned issues from cache (reactive).
final assignedIssuesProvider = StreamProvider<List<CachedIssue>>((ref) {
  final dao = ref.watch(cachedIssueDaoProvider);
  return dao.watchAssignedIssues();
});

/// Recently tracked issues (last 5).
final recentTrackedIssuesProvider =
    FutureProvider<List<TimeEntry>>((ref) async {
  final dao = ref.watch(timeEntryDaoProvider);
  return dao.getRecentTrackedIssues();
});

/// Trigger a sync of assigned issues from Linear.
final syncIssuesProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(issueRepositoryProvider);
  if (repo == null) return;
  await repo.syncAssignedIssues();
});
