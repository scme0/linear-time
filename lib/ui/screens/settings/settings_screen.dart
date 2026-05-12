import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/api/linear_api_client.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/database_providers.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_utils.dart';
import '../../../services/hotkey_service.dart';
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

  Future<void> _exportCsv() async {
    final dao = ref.read(timeEntryDaoProvider);
    final csv = await exportToCsv(dao);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/linear_time_export_$timestamp.csv');
    await file.writeAsString(csv);
    if (mounted) {
      setState(() => _exportResult = 'Exported to ${file.path}');
    }
  }

  Future<void> _importCsv() async {
    // Use a simple file path input for now
    final dir = await getApplicationDocumentsDirectory();
    // Find the most recent export file
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.csv') && f.path.contains('linear_time'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (files.isEmpty) {
      if (mounted) setState(() => _exportResult = 'No CSV files found in ${dir.path}');
      return;
    }

    final file = files.first;
    final content = await file.readAsString();
    final dao = ref.read(timeEntryDaoProvider);
    final count = await importFromCsv(dao, content);
    if (mounted) {
      setState(() => _exportResult = 'Imported $count entries from ${file.uri.pathSegments.last}');
    }
  }

  String? _exportResult;

  static const _platform = MethodChannel('com.lineartime/system');

  Future<void> _setLaunchAtLogin(bool enabled) async {
    try {
      await _platform.invokeMethod('setLaunchAtLogin', {'enabled': enabled});
    } on PlatformException {
      // SMAppService not available on older macOS
    }
  }

  Future<void> _setShowInDock(bool show) async {
    try {
      await _platform.invokeMethod('setShowInDock', {'show': show});
    } on PlatformException {
      // Fallback
    }
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
                    items: [1, 2, 5, 10, 15, 20, 30, 45, 60]
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
                    items: [1, 2, 5, 10, 15, 30, 45, 60]
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
                  onChanged: (v) async {
                    await saveBool(ref, SettingsKeys.launchAtLogin, v);
                    await _setLaunchAtLogin(v);
                  },
                ),
              ),
              SettingRow(
                label: 'Show in Dock',
                description: 'When off, app only appears in menubar',
                control: MacosSwitch(
                  value: settings.showInDock,
                  onChanged: (v) async {
                    await saveBool(ref, SettingsKeys.showInDock, v);
                    await _setShowInDock(v);
                  },
                ),
              ),
              _HotkeySettingRow(
                brightness: brightness,
              ),
              SettingRow(
                label: 'Hotkey default filter',
                description: 'Which issues to show when hotkey is pressed',
                control: MacosPopupButton<String>(
                  value: settings.hotkeyFilter,
                  items: const [
                    MacosPopupMenuItem(
                      value: 'myIssues',
                      child: Text('My Issues'),
                    ),
                    MacosPopupMenuItem(
                      value: 'allIssues',
                      child: Text('All Issues'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      saveSetting(ref, SettingsKeys.hotkeyFilter, v);
                    }
                  },
                ),
              ),
            ],
          ),

          // ── Data ──
          SettingsSection(
            title: 'Data',
            children: [
              FutureBuilder<Directory>(
                future: getApplicationDocumentsDirectory(),
                builder: (context, snapshot) {
                  return SettingRow(
                    label: 'Database location',
                    description: snapshot.hasData
                        ? '${snapshot.data!.path}/linear_time.sqlite'
                        : 'Loading...',
                    control: snapshot.hasData
                        ? PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text:
                                      '${snapshot.data!.path}/linear_time.sqlite'));
                            },
                            child: const Text('Copy Path'),
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
              SettingRow(
                label: 'Export time entries',
                description: 'Download all time entries as CSV',
                control: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: _exportCsv,
                  child: const Text('Export CSV'),
                ),
              ),
              SettingRow(
                label: 'Import time entries',
                description: 'Restore from a CSV backup',
                control: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: _importCsv,
                  child: const Text('Import CSV'),
                ),
              ),
              SettingRow(
                label: 'Clear all data',
                description: 'Delete all time entries and cached issues',
                control: _DangerButton(
                  label: 'Clear Data',
                  onPressed: () => _confirmClearData(context),
                ),
              ),
              if (_exportResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    _exportResult!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(brightness),
                    ),
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

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          color: AppColors.danger,
          size: 48,
        ),
        title: const Text('Clear all data?'),
        message: const Text(
          'This will permanently delete all time entries and cached issues. '
          'This action cannot be undone.',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Clear Data',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.timeEntryDao.deleteAll();
      await db.cachedIssueDao.clearAll();
      await db.settingsDao.clearAll();
      ref.invalidate(appSettingsProvider);
    }
  }

  Widget _buildLinearSection(Brightness brightness, bool isConnected) {
    return SettingsSection(
      title: 'Linear Connection',
      children: [
        if (isConnected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your Linear API key to connect:',
                  style: TextStyle(
                      color: AppColors.textSecondary(brightness)),
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
            ),
          ),
      ],
    );
  }

  Widget _buildOfficeDays(AppSettings settings, Brightness brightness) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayValues = [1, 2, 3, 4, 5, 6, 7];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _DangerButton extends StatefulWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.danger
                : AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hovering ? const Color(0xFFFFFFFF) : AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hotkey recorder row for settings.
class _HotkeySettingRow extends ConsumerStatefulWidget {
  const _HotkeySettingRow({required this.brightness});

  final Brightness brightness;

  @override
  ConsumerState<_HotkeySettingRow> createState() => _HotkeySettingRowState();
}

class _HotkeySettingRowState extends ConsumerState<_HotkeySettingRow> {
  bool _recording = false;
  String? _currentDisplay;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    final dao = ref.read(settingsDaoProvider);
    final val = await dao.getValue(SettingsKeys.globalHotkey);
    if (val != null && val.isNotEmpty && mounted) {
      setState(() {
        _currentDisplay = HotkeyCombo.fromString(val).toDisplayString();
      });
    }
  }

  void _startRecording() {
    setState(() => _recording = true);
    _focusNode.requestFocus();
  }

  Future<void> _clearHotkey() async {
    await HotkeyService.clearHotkey();
    final dao = ref.read(settingsDaoProvider);
    await dao.deleteValue(SettingsKeys.globalHotkey);
    setState(() {
      _currentDisplay = null;
      _recording = false;
    });
  }

  Future<void> _onKeyEvent(KeyEvent event) async {
    if (!_recording) return;
    if (event is! KeyDownEvent) return;

    // Need at least one modifier
    final mods = HardwareKeyboard.instance.logicalKeysPressed;
    int modFlags = 0;
    bool hasModifier = false;
    for (final key in mods) {
      if (key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight) {
        modFlags |= MacModifier.control;
        hasModifier = true;
      }
      if (key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        modFlags |= MacModifier.shift;
        hasModifier = true;
      }
      if (key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        modFlags |= MacModifier.option;
        hasModifier = true;
      }
      if (key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        modFlags |= MacModifier.command;
        hasModifier = true;
      }
    }

    if (!hasModifier) return;

    // Ignore bare modifier presses
    final physicalKey = event.physicalKey;
    if (physicalKey == PhysicalKeyboardKey.controlLeft ||
        physicalKey == PhysicalKeyboardKey.controlRight ||
        physicalKey == PhysicalKeyboardKey.shiftLeft ||
        physicalKey == PhysicalKeyboardKey.shiftRight ||
        physicalKey == PhysicalKeyboardKey.altLeft ||
        physicalKey == PhysicalKeyboardKey.altRight ||
        physicalKey == PhysicalKeyboardKey.metaLeft ||
        physicalKey == PhysicalKeyboardKey.metaRight) {
      return;
    }

    // Map logical key to macOS keyCode (approximate via USB HID)
    final keyCode = _logicalToMacKeyCode(event.logicalKey);
    if (keyCode < 0) return;

    final combo = HotkeyCombo(keyCode: keyCode, modifiers: modFlags);
    await HotkeyService.setHotkey(
        keyCode: combo.keyCode, modifiers: combo.modifiers);
    final dao = ref.read(settingsDaoProvider);
    await dao.setValue(SettingsKeys.globalHotkey, combo.toSettingsString());

    setState(() {
      _currentDisplay = combo.toDisplayString();
      _recording = false;
    });
  }

  int _logicalToMacKeyCode(LogicalKeyboardKey key) {
    // Map common keys to macOS virtual key codes
    final map = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.keyA: 0, LogicalKeyboardKey.keyS: 1,
      LogicalKeyboardKey.keyD: 2, LogicalKeyboardKey.keyF: 3,
      LogicalKeyboardKey.keyH: 4, LogicalKeyboardKey.keyG: 5,
      LogicalKeyboardKey.keyZ: 6, LogicalKeyboardKey.keyX: 7,
      LogicalKeyboardKey.keyC: 8, LogicalKeyboardKey.keyV: 9,
      LogicalKeyboardKey.keyB: 11, LogicalKeyboardKey.keyQ: 12,
      LogicalKeyboardKey.keyW: 13, LogicalKeyboardKey.keyE: 14,
      LogicalKeyboardKey.keyR: 15, LogicalKeyboardKey.keyY: 16,
      LogicalKeyboardKey.keyT: 17, LogicalKeyboardKey.digit1: 18,
      LogicalKeyboardKey.digit2: 19, LogicalKeyboardKey.digit3: 20,
      LogicalKeyboardKey.digit4: 21, LogicalKeyboardKey.digit6: 22,
      LogicalKeyboardKey.digit5: 23, LogicalKeyboardKey.digit9: 25,
      LogicalKeyboardKey.digit7: 26, LogicalKeyboardKey.digit8: 28,
      LogicalKeyboardKey.digit0: 29, LogicalKeyboardKey.keyO: 31,
      LogicalKeyboardKey.keyU: 32, LogicalKeyboardKey.keyI: 34,
      LogicalKeyboardKey.keyP: 35, LogicalKeyboardKey.keyL: 37,
      LogicalKeyboardKey.keyJ: 38, LogicalKeyboardKey.keyK: 40,
      LogicalKeyboardKey.keyN: 45, LogicalKeyboardKey.keyM: 46,
      LogicalKeyboardKey.space: 49,
    };
    return map[key] ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global hotkey',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary(widget.brightness),
                  ),
                ),
                Text(
                  'Toggle timer from anywhere',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(widget.brightness),
                  ),
                ),
              ],
            ),
          ),
          if (_currentDisplay != null && !_recording) ...[
            Text(
              _currentDisplay!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(widget.brightness),
              ),
            ),
            const SizedBox(width: 8),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _clearHotkey,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 4),
          ],
          KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: _onKeyEvent,
            child: PushButton(
              controlSize: ControlSize.regular,
              onPressed: _recording
                  ? () => setState(() => _recording = false)
                  : _startRecording,
              child: Text(_recording
                  ? 'Cancel'
                  : _currentDisplay != null
                      ? 'Change'
                      : 'Record'),
            ),
          ),
        ],
      ),
    );
  }
}
