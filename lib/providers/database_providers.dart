import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/time_entry_dao.dart';
import '../data/database/daos/cached_issue_dao.dart';
import '../data/database/daos/settings_dao.dart';

/// Singleton database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final timeEntryDaoProvider = Provider<TimeEntryDao>((ref) {
  return ref.watch(databaseProvider).timeEntryDao;
});

final cachedIssueDaoProvider = Provider<CachedIssueDao>((ref) {
  return ref.watch(databaseProvider).cachedIssueDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(databaseProvider).settingsDao;
});
