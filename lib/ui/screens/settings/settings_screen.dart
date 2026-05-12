import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../data/api/linear_api_client.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _testing = false;
  String? _testResult;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final client = LinearApiClient(apiKey: key);
      final viewer = await client.fetchViewer();
      if (viewer != null) {
        await setApiKey(ref, key);
        ref.invalidate(issueRepositoryProvider);
        ref.invalidate(syncIssuesProvider);
        setState(() {
          _testResult = 'Connected as ${viewer['name']} (${viewer['email']})';
        });
      } else {
        setState(() => _testResult = 'Failed — invalid API key');
      }
    } catch (e) {
      setState(() => _testResult = 'Error: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _disconnect() async {
    final repo = ref.read(issueRepositoryProvider);
    await repo?.clearCache();
    await setApiKey(ref, null);
    _apiKeyController.clear();
    setState(() => _testResult = null);
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final isConnected = apiKey.valueOrNull != null;
    final settingsAsync = ref.watch(appSettingsProvider);
    final brightness = MacosTheme.of(context).brightness;

    return settingsAsync.when(
      data: (settings) => _buildContent(
          context, brightness, isConnected, settings),
      loading: () => const Center(child: ProgressCircle()),
      error: (e, _) => Center(child: Text('Error loading settings: $e')),
    );
  }

  Widget _buildContent(BuildContext context, Brightness brightness,
      bool isConnected, AppSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Linear Connection ──
          _buildLinearSection(brightness, isConnected),

          // ── Sync ──
          SettingsSection(
            title: 'Sync',
            children: [
              SettingRow(
                label: 'Sync on launch',
                description: 'Fetch issues from Linear when app starts',
                control: MacosSwitch(
                  value: settings.syncOnLaunch,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.syncOnLaunch, v),
                ),
              ),
              SettingRow(
                label: 'Sync interval',
                description: 'How often to refresh issues in the background',
                control: MacosPopupButton<int>(
                  value: settings.syncIntervalMinutes,
                  items: [5, 15, 30, 60]
                      .map((v) => MacosPopupMenuItem(
                            value: v,
                            child: Text(v == 60 ? '1 hour' : '$v min'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      saveInt(ref, SettingsKeys.syncIntervalMinutes, v);
                    }
                  },
                ),
              ),
              SettingRow(
                label: 'Show completed issues',
                description: 'Include completed/cancelled issues in the list',
                control: MacosSwitch(
                  value: settings.showCompletedIssues,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.showCompletedIssues, v),
                ),
              ),
            ],
          ),

          // ── Timer Behavior ──
          SettingsSection(
            title: 'Timer Behavior',
            children: [
              SettingRow(
                label: 'Minimum entry duration',
                description: 'Discard entries shorter than this (seconds)',
                control: MacosPopupButton<int>(
                  value: settings.minEntryDurationSeconds,
                  items: [0, 3, 5, 10, 30]
                      .map((v) => MacosPopupMenuItem(
                            value: v,
                            child: Text(v == 0 ? 'Off' : '${v}s'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      saveInt(
                          ref, SettingsKeys.minEntryDurationSeconds, v);
                    }
                  },
                ),
              ),
              SettingRow(
                label: 'Time display format',
                control: MacosPopupButton<String>(
                  value: settings.timeDisplayFormat,
                  items: const [
                    MacosPopupMenuItem(
                      value: 'hms',
                      child: Text('HH:MM:SS'),
                    ),
                    MacosPopupMenuItem(
                      value: 'decimal',
                      child: Text('Decimal (1.5h)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      saveSetting(ref, SettingsKeys.timeDisplayFormat, v);
                    }
                  },
                ),
              ),
            ],
          ),

          // ── Notifications ──
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingRow(
                label: 'Office hours',
                description: 'Notifications only fire during these hours',
                control: MacosSwitch(
                  value: settings.officeHoursEnabled,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.officeHoursEnabled, v),
                ),
              ),
              if (settings.officeHoursEnabled) ...[
                SettingRow(
                  label: 'Start hour',
                  control: MacosPopupButton<int>(
                    value: settings.officeStartHour,
                    items: List.generate(
                      24,
                      (i) => MacosPopupMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) {
                        saveInt(ref, SettingsKeys.officeStartHour, v);
                      }
                    },
                  ),
                ),
                SettingRow(
                  label: 'End hour',
                  control: MacosPopupButton<int>(
                    value: settings.officeEndHour,
                    items: List.generate(
                      24,
                      (i) => MacosPopupMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) {
                        saveInt(ref, SettingsKeys.officeEndHour, v);
                      }
                    },
                  ),
                ),
                _buildOfficeDays(settings, brightness),
              ],
              SettingRow(
                label: 'Idle detection',
                description: '"Are you still working?" after inactivity',
                control: MacosSwitch(
                  value: settings.idleDetectionEnabled,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.idleDetectionEnabled, v),
                ),
              ),
              if (settings.idleDetectionEnabled)
                SettingRow(
                  label: 'Idle delay',
                  control: MacosPopupButton<int>(
                    value: settings.idleDelayMinutes,
                    items: [5, 10, 15, 20, 30, 45, 60]
                        .map((v) => MacosPopupMenuItem(
                              value: v,
                              child: Text('$v min'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        saveInt(ref, SettingsKeys.idleDelayMinutes, v);
                      }
                    },
                  ),
                ),
              SettingRow(
                label: 'Forgotten timer',
                description: '"Did you forget your timer?" when no timer running',
                control: MacosSwitch(
                  value: settings.forgottenTimerEnabled,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.forgottenTimerEnabled, v),
                ),
              ),
              if (settings.forgottenTimerEnabled)
                SettingRow(
                  label: 'Reminder delay',
                  control: MacosPopupButton<int>(
                    value: settings.forgottenTimerDelayMinutes,
                    items: [10, 15, 30, 45, 60]
                        .map((v) => MacosPopupMenuItem(
                              value: v,
                              child: Text('$v min'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        saveInt(ref,
                            SettingsKeys.forgottenTimerDelayMinutes, v);
                      }
                    },
                  ),
                ),
            ],
          ),

          // ── Appearance ──
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingRow(
                label: 'Theme',
                control: MacosPopupButton<String>(
                  value: settings.themeMode,
                  items: const [
                    MacosPopupMenuItem(
                        value: 'system', child: Text('System')),
                    MacosPopupMenuItem(
                        value: 'light', child: Text('Light')),
                    MacosPopupMenuItem(
                        value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      saveSetting(ref, SettingsKeys.themeMode, v);
                    }
                  },
                ),
              ),
            ],
          ),

          // ── System ──
          SettingsSection(
            title: 'System',
            children: [
              SettingRow(
                label: 'Launch at login',
                control: MacosSwitch(
                  value: settings.launchAtLogin,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.launchAtLogin, v),
                ),
              ),
              SettingRow(
                label: 'Show in Dock',
                description: 'When off, app only appears in menubar',
                control: MacosSwitch(
                  value: settings.showInDock,
                  onChanged: (v) =>
                      saveBool(ref, SettingsKeys.showInDock, v),
                ),
              ),
            ],
          ),

          // ── Data ──
          SettingsSection(
            title: 'Data',
            children: [
              SettingRow(
                label: 'Export time entries',
                description: 'Download all time entries as CSV',
                control: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () {
                    // TODO: implement CSV export
                  },
                  child: const Text('Export CSV'),
                ),
              ),
              SettingRow(
                label: 'Import time entries',
                description: 'Restore from a CSV backup',
                control: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () {
                    // TODO: implement CSV import
                  },
                  child: const Text('Import CSV'),
                ),
              ),
              SettingRow(
                label: 'Clear all data',
                description: 'Delete all time entries and cached issues',
                control: PushButton(
                  controlSize: ControlSize.regular,
                  color: AppColors.danger,
                  onPressed: () {
                    // TODO: confirmation dialog + clear
                  },
                  child: const Text('Clear Data'),
                ),
              ),
            ],
          ),

          // Version
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Linear Time v0.0.1',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary(brightness),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinearSection(Brightness brightness, bool isConnected) {
    return SettingsSection(
      title: 'Linear Connection',
      children: [
        if (isConnected) ...[
          Row(
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Connected to Linear',
                style: TextStyle(
                    color: AppColors.textPrimary(brightness)),
              ),
            ],
          ),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _testResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(brightness),
                ),
              ),
            ),
          const SizedBox(height: 12),
          PushButton(
            controlSize: ControlSize.regular,
            onPressed: _disconnect,
            child: const Text('Disconnect'),
          ),
        ] else ...[
          Text(
            'Enter your Linear API key to connect:',
            style: TextStyle(color: AppColors.textSecondary(brightness)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 400,
            child: MacosTextField(
              controller: _apiKeyController,
              placeholder: 'lin_api_...',
              placeholderStyle: TextStyle(
                color: AppColors.textSecondary(brightness),
              ),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 12),
          PushButton(
            controlSize: ControlSize.regular,
            onPressed: _testing ? null : _testConnection,
            child: _testing
                ? const ProgressCircle(radius: 8)
                : const Text('Connect'),
          ),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.startsWith('Connected')
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildOfficeDays(AppSettings settings, Brightness brightness) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayValues = [1, 2, 3, 4, 5, 6, 7];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Office days',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(7, (i) {
              final isActive = settings.officeDays.contains(dayValues[i]);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () {
                    final newDays = List<int>.from(settings.officeDays);
                    if (isActive) {
                      newDays.remove(dayValues[i]);
                    } else {
                      newDays.add(dayValues[i]);
                    }
                    newDays.sort();
                    saveSetting(ref, SettingsKeys.officeDays,
                        newDays.join(','));
                  },
                  child: Container(
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.surface2(brightness),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.border(brightness),
                        width: isActive ? 1.5 : 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textSecondary(brightness),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
