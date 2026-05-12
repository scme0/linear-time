import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cached_issues.dart';

part 'cached_issue_dao.g.dart';

@DriftAccessor(tables: [CachedIssues])
class CachedIssueDao extends DatabaseAccessor<AppDatabase>
    with _$CachedIssueDaoMixin {
  CachedIssueDao(super.db);

  /// Upsert an issue into the cache.
  Future<void> upsertIssue(CachedIssuesCompanion issue) {
    return into(cachedIssues).insertOnConflictUpdate(issue);
  }

  /// Upsert multiple issues.
  Future<void> upsertIssues(List<CachedIssuesCompanion> issues) async {
    await batch((batch) {
      for (final issue in issues) {
        batch.insert(cachedIssues, issue, onConflict: DoUpdate((_) => issue));
      }
    });
  }

  /// Get all non-deleted cached issues assigned to user, ordered by priority.
  Future<List<CachedIssue>> getAssignedIssues() {
    return (select(cachedIssues)
          ..where((i) => i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm.asc(i.priority)]))
        .get();
  }

  /// Watch assigned issues for reactive UI updates.
  Stream<List<CachedIssue>> watchAssignedIssues() {
    return (select(cachedIssues)
          ..where((i) => i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm.asc(i.priority)]))
        .watch();
  }

  /// Get issues filtered by team.
  Future<List<CachedIssue>> getIssuesByTeam(String teamId) {
    return (select(cachedIssues)
          ..where(
              (i) => i.teamId.equals(teamId) & i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm.asc(i.priority)]))
        .get();
  }

  /// Get issues filtered by project.
  Future<List<CachedIssue>> getIssuesByProject(String projectId) {
    return (select(cachedIssues)
          ..where((i) =>
              i.projectId.equals(projectId) & i.isDeleted.equals(false))
          ..orderBy([(i) => OrderingTerm.asc(i.priority)]))
        .get();
  }

  /// Search issues by identifier or title.
  Future<List<CachedIssue>> searchIssues(String query) {
    final pattern = '%$query%';
    return (select(cachedIssues)
          ..where((i) =>
              i.identifier.like(pattern) | i.title.like(pattern))
          ..orderBy([(i) => OrderingTerm.asc(i.priority)]))
        .get();
  }

  /// Get a single issue by ID.
  Future<CachedIssue?> getIssueById(String issueId) {
    return (select(cachedIssues)..where((i) => i.issueId.equals(issueId)))
        .getSingleOrNull();
  }

  /// Get a single issue by identifier (e.g. "ENG-123").
  Future<CachedIssue?> getIssueByIdentifier(String identifier) {
    return (select(cachedIssues)
          ..where((i) => i.identifier.equals(identifier)))
        .getSingleOrNull();
  }

  /// Mark an issue as deleted.
  Future<void> markDeleted(String issueId) {
    return (update(cachedIssues)..where((i) => i.issueId.equals(issueId)))
        .write(const CachedIssuesCompanion(isDeleted: Value(true)));
  }

  /// Mark multiple issues as deleted.
  Future<void> markDeletedBatch(List<String> issueIds) async {
    await (update(cachedIssues)
          ..where((i) => i.issueId.isIn(issueIds)))
        .write(const CachedIssuesCompanion(isDeleted: Value(true)));
  }

  /// Get all cached issue IDs (for sync comparison).
  Future<List<String>> getAllIssueIds() async {
    final results = await (selectOnly(cachedIssues)
          ..addColumns([cachedIssues.issueId]))
        .get();
    return results.map((r) => r.read(cachedIssues.issueId)!).toList();
  }

  /// Clear all cached issues (for disconnect).
  Future<void> clearAll() {
    return delete(cachedIssues).go();
  }
}
