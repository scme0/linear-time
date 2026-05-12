import 'package:drift/drift.dart';

import '../api/linear_api_client.dart';
import '../database/app_database.dart';
import '../database/daos/cached_issue_dao.dart';

class IssueRepository {
  IssueRepository({
    required this.apiClient,
    required this.cachedIssueDao,
  });

  final LinearApiClient apiClient;
  final CachedIssueDao cachedIssueDao;

  /// Sync assigned issues from Linear into cache.
  /// Detects deleted issues by comparing cached IDs with API response.
  Future<void> syncAssignedIssues({
    bool showCompleted = false,
  }) async {
    final excludeTypes =
        showCompleted ? <String>[] : ['completed', 'cancelled'];

    final apiIssues = await apiClient.fetchAssignedIssues(
      excludeStatusTypes: excludeTypes.isEmpty ? null : excludeTypes,
    );

    if (apiIssues.isEmpty) return;

    final companions = apiIssues
        .map((d) => _mapToCompanion(d, isAssigned: true))
        .toList();
    await cachedIssueDao.upsertIssues(companions);
  }

  /// Sync all issues from all user's teams into cache.
  Future<void> syncAllTeamIssues({bool showCompleted = false}) async {
    final excludeTypes =
        showCompleted ? <String>[] : ['completed', 'cancelled'];

    final teams = await apiClient.fetchTeams();
    for (final team in teams) {
      final teamId = team['id'] as String;
      final apiIssues = await apiClient.fetchTeamIssues(
        teamId: teamId,
        excludeStatusTypes: excludeTypes.isEmpty ? null : excludeTypes,
      );
      if (apiIssues.isNotEmpty) {
        // Don't set isAssigned — preserve existing value for already-assigned issues
        final companions = apiIssues
            .map((d) => _mapToCompanion(d, preserveAssigned: true))
            .toList();
        await cachedIssueDao.upsertIssues(companions);
      }
    }
  }

  /// Fetch and cache a single issue by ID.
  Future<CachedIssue?> fetchAndCacheIssue(String issueId) async {
    final data = await apiClient.fetchIssueById(issueId);
    if (data == null) return null;
    await cachedIssueDao.upsertIssue(_mapToCompanion(data));
    return cachedIssueDao.getIssueById(data['id'] as String);
  }

  /// Fetch and cache an issue by identifier (e.g. "ENG-123").
  Future<CachedIssue?> fetchAndCacheByIdentifier(String identifier) async {
    final data = await apiClient.fetchIssueByIdentifier(identifier);
    if (data == null) return null;
    await cachedIssueDao.upsertIssue(_mapToCompanion(data));
    return cachedIssueDao.getIssueById(data['id'] as String);
  }

  /// Resolve a search query — could be an identifier, URL, or text search.
  Future<CachedIssue?> resolveIssueQuery(String query) async {
    final trimmed = query.trim();

    // Check if it's a Linear URL
    final urlMatch = RegExp(r'linear\.app/.+/issue/([A-Z]+-\d+)')
        .firstMatch(trimmed);
    if (urlMatch != null) {
      return fetchAndCacheByIdentifier(urlMatch.group(1)!);
    }

    // Check if it's an identifier like "ENG-123"
    if (RegExp(r'^[A-Z]+-\d+$').hasMatch(trimmed)) {
      return fetchAndCacheByIdentifier(trimmed);
    }

    // Check if it's a UUID
    if (RegExp(r'^[0-9a-f-]{36}$').hasMatch(trimmed)) {
      return fetchAndCacheIssue(trimmed);
    }

    // Fall back to local search
    final localResults = await cachedIssueDao.searchIssues(trimmed);
    return localResults.firstOrNull;
  }

  /// Clear all cached data (for disconnect).
  Future<void> clearCache() => cachedIssueDao.clearAll();

  CachedIssuesCompanion _mapToCompanion(Map<String, dynamic> data,
      {bool isAssigned = false, bool preserveAssigned = false}) {
    final team = data['team'] as Map<String, dynamic>?;
    final project = data['project'] as Map<String, dynamic>?;
    final state = data['state'] as Map<String, dynamic>?;
    final assignee = data['assignee'] as Map<String, dynamic>?;

    return CachedIssuesCompanion(
      issueId: Value(data['id'] as String),
      identifier: Value(data['identifier'] as String),
      title: Value(data['title'] as String),
      teamId: Value(team?['id'] as String?),
      teamName: Value(team?['name'] as String?),
      teamColor: Value(team?['color'] as String?),
      projectId: Value(project?['id'] as String?),
      projectName: Value(project?['name'] as String?),
      status: Value(state?['name'] as String? ?? 'Unknown'),
      statusType: Value(state?['type'] as String? ?? 'unstarted'),
      priority: Value(data['priority'] as int? ?? 0),
      url: Value(data['url'] as String? ?? ''),
      assigneeId: Value(assignee?['id'] as String?),
      assigneeName: Value(assignee?['name'] as String?),
      isDeleted: const Value(false),
      isAssigned: preserveAssigned ? const Value.absent() : Value(isAssigned),
      lastSynced: Value(DateTime.now()),
    );
  }
}
