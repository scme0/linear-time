import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'database_providers.dart';

/// All app settings as a typed object.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  final all = await dao.getAll();
  return AppSettings.fromMap(all);
});

/// Save a single setting and invalidate the provider.
Future<void> saveSetting(WidgetRef ref, String key, String value) async {
  final dao = ref.read(settingsDaoProvider);
  await dao.setValue(key, value);
  ref.invalidate(appSettingsProvider);
}

/// Save a bool setting.
Future<void> saveBool(WidgetRef ref, String key, bool value) =>
    saveSetting(ref, key, value.toString());

/// Save an int setting.
Future<void> saveInt(WidgetRef ref, String key, int value) =>
    saveSetting(ref, key, value.toString());

class AppSettings {
  const AppSettings({
    this.showCompletedIssues = false,
    this.idleDetectionEnabled = true,
    this.idleDelayMinutes = kDefaultIdleDelayMinutes,
    this.forgottenTimerEnabled = true,
    this.forgottenTimerDelayMinutes = kDefaultForgottenTimerDelayMinutes,
    this.officeHoursEnabled = true,
    this.officeStartHour = kDefaultOfficeStartHour,
    this.officeEndHour = kDefaultOfficeEndHour,
    this.officeDays = const [1, 2, 3, 4, 5],
    this.launchAtLogin = false,
    this.timeDisplayFormat = 'human',
    this.minEntryDurationSeconds = kDefaultMinEntryDurationSeconds,
    this.themeMode = 'system',
    this.hotkeyFilter = 'myIssues',
    this.notificationStyle = 'overlay',
  });

  final bool showCompletedIssues;
  final bool idleDetectionEnabled;
  final int idleDelayMinutes;
  final bool forgottenTimerEnabled;
  final int forgottenTimerDelayMinutes;
  final bool officeHoursEnabled;
  final int officeStartHour;
  final int officeEndHour;
  final List<int> officeDays;
  final bool launchAtLogin;
  final String timeDisplayFormat;
  final int minEntryDurationSeconds;
  final String themeMode;
  final String hotkeyFilter;
  final String notificationStyle;

  ThemeMode get flutterThemeMode => switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  factory AppSettings.fromMap(Map<String, String> m) {
    return AppSettings(
      showCompletedIssues: _bool(m, SettingsKeys.showCompletedIssues, false),
      idleDetectionEnabled: _bool(m, SettingsKeys.idleDetectionEnabled, true),
      idleDelayMinutes: _int(m, SettingsKeys.idleDelayMinutes, kDefaultIdleDelayMinutes),
      forgottenTimerEnabled: _bool(m, SettingsKeys.forgottenTimerEnabled, true),
      forgottenTimerDelayMinutes: _int(m, SettingsKeys.forgottenTimerDelayMinutes, kDefaultForgottenTimerDelayMinutes),
      officeHoursEnabled: _bool(m, SettingsKeys.officeHoursEnabled, true),
      officeStartHour: _int(m, SettingsKeys.officeStartHour, kDefaultOfficeStartHour),
      officeEndHour: _int(m, SettingsKeys.officeEndHour, kDefaultOfficeEndHour),
      officeDays: _intList(m, SettingsKeys.officeDays, [1, 2, 3, 4, 5]),
      launchAtLogin: _bool(m, SettingsKeys.launchAtLogin, false),
      timeDisplayFormat: m[SettingsKeys.timeDisplayFormat] ?? 'human',
      minEntryDurationSeconds: _int(m, SettingsKeys.minEntryDurationSeconds, kDefaultMinEntryDurationSeconds),
      themeMode: m[SettingsKeys.themeMode] ?? 'system',
      hotkeyFilter: m[SettingsKeys.hotkeyFilter] ?? 'myIssues',
      notificationStyle: m[SettingsKeys.notificationStyle] ?? 'overlay',
    );
  }

  static bool _bool(Map<String, String> m, String key, bool def) =>
      m[key] == null ? def : m[key] == 'true';

  static int _int(Map<String, String> m, String key, int def) =>
      m[key] == null ? def : (int.tryParse(m[key]!) ?? def);

  static List<int> _intList(Map<String, String> m, String key, List<int> def) {
    final val = m[key];
    if (val == null || val.isEmpty) return def;
    return val.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((i) => i > 0).toList();
  }
}
