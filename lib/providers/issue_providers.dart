import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'api_providers.dart';
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

/// Teams from Linear API (teams user is a member of).
final teamsProvider = FutureProvider<List<({String id, String name})>>((ref) async {
  final client = ref.watch(linearApiClientProvider);
  if (client == null) return [];
  final teams = await client.fetchTeams();
  return teams
      .map((t) => (id: t['id'] as String, name: t['name'] as String))
      .toList();
});

/// Projects from Linear API (projects in user's teams).
final projectsProvider = FutureProvider<List<({String id, String name})>>((ref) async {
  final client = ref.watch(linearApiClientProvider);
  if (client == null) return [];
  final projects = await client.fetchProjects();
  return projects
      .map((p) => (id: p['id'] as String, name: p['name'] as String))
      .toList();
});
