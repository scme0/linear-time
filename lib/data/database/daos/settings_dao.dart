import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Get a setting value by key.
  Future<String?> getValue(String key) async {
    final result = await (select(settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Set a setting value (insert or update).
  Future<void> setValue(String key, String value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }

  /// Delete a setting.
  Future<void> deleteValue(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  /// Get all settings as a map.
  Future<Map<String, String>> getAll() async {
    final results = await select(settings).get();
    return {for (final r in results) r.key: r.value};
  }

  /// Clear all settings.
  Future<void> clearAll() {
    return delete(settings).go();
  }
}
