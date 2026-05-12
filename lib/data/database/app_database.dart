import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/time_entries.dart';
import 'tables/cached_issues.dart';
import 'tables/settings.dart';
import 'daos/time_entry_dao.dart';
import 'daos/cached_issue_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TimeEntries, CachedIssues, Settings],
  daos: [TimeEntryDao, CachedIssueDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'linear_time');
  }
}
