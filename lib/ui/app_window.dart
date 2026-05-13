import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../providers/api_providers.dart';
import '../providers/database_providers.dart';
import '../providers/issue_providers.dart';
import '../providers/repository_providers.dart';
import '../core/constants.dart';
import '../core/theme/app_theme.dart';
import '../core/time_format.dart';
import '../providers/settings_providers.dart';
import 'package:intl/intl.dart';
import '../services/hotkey_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import 'tray/tray_manager.dart';
import 'screens/timer/timer_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/history/daily/widgets/time_entry_dialog.dart';
import 'screens/settings/settings_screen.dart';

class AppWindow extends ConsumerStatefulWidget {
  const AppWindow({super.key});

  @override
  ConsumerState<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends ConsumerState<AppWindow> with WidgetsBindingObserver {
  int _pageIndex = 0;
  bool _hotkeyInitialized = false;
  final _searchFocusNotifier = ValueNotifier<int>(0);
  final _hotkeyFilterNotifier = ValueNotifier<String?>('myIssues');
  final _filterModeNotifier = ValueNotifier<IssueFilterMode?>(null);
  TrayManager? _trayManager;
  NotificationService? _notificationService;
  SyncService? _syncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    if (!meta) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyS:
        final repo = ref.read(timeTrackingRepositoryProvider);
        repo.stopTimer();
        TrayManager.instance?.updateMenu();
        TrayManager.instance?.updateTitle();
        NotificationService.instance?.onTimerStateChanged();
        return true;
      case LogicalKeyboardKey.keyF:
        setState(() => _pageIndex = 0);
        Future.delayed(const Duration(milliseconds: 50), () {
          _searchFocusNotifier.value++;
        });
        return true;
      case LogicalKeyboardKey.keyN:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        showMacosAlertDialog<bool>(
          context: context,
          builder: (ctx) => TimeEntryDialog(date: today),
        );
        return true;
      case LogicalKeyboardKey.keyM:
        setState(() => _pageIndex = 0);
        _filterModeNotifier.value = IssueFilterMode.myIssues;
        return true;
      case LogicalKeyboardKey.keyE:
        setState(() => _pageIndex = 0);
        _filterModeNotifier.value = IssueFilterMode.allIssues;
        return true;
      case LogicalKeyboardKey.keyR:
        setState(() => _pageIndex = 0);
        _filterModeNotifier.value = IssueFilterMode.recentlyTracked;
        return true;
      case LogicalKeyboardKey.comma:
        setState(() => _pageIndex = 2);
        return true;
      case LogicalKeyboardKey.slash:
        _showCheatsheet(context, MacosTheme.of(context).brightness);
        return true;
      default:
        return false;
    }
  }

  void _showCheatsheet(BuildContext context, Brightness brightness) {
    showMacosAlertDialog(
      context: context,
      builder: (ctx) => MacosAlertDialog(
        appIcon: const Icon(CupertinoIcons.keyboard, size: 48),
        title: const Text('Keyboard Shortcuts'),
        message: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _shortcuts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface2(brightness),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.border(brightness),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          entry.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Menlo',
                            color: AppColors.textPrimary(brightness),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Done'),
        ),
      ),
    );
  }

  static const _shortcuts = [
    ('⌘+F', 'Focus search bar'),
    ('↑ ↓', 'Navigate issue list'),
    ('⏎', 'Select issue & start timer'),
    ('⌘+S', 'Stop timer'),
    ('⌘+N', 'New manual entry'),
    ('⌘+⏎', 'Save (in dialogs)'),
    ('⌘+M', 'My Issues'),
    ('⌘+E', "Everyone's Issues"),
    ('⌘+R', 'Recently Tracked'),
    ('⌘+,', 'Settings'),
    ('⌘+/', 'This cheatsheet'),
    ('Esc', 'Cancel / Unfocus'),
  ];

  void _initNotifications() {
    if (_notificationService != null) return;
    _notificationService = NotificationService(ref);
    NotificationService.instance = _notificationService;
    _notificationService!.init();
  }

  void _initSync() {
    if (_syncService != null) return;
    _syncService = SyncService(ref);
    _syncService!.init();
  }

  void _initTray() {
    if (_trayManager != null) return;
    _trayManager = TrayManager(ref, onNavigate: (tab) {
      setState(() => _pageIndex = tab);
    });
    TrayManager.instance = _trayManager;
    _trayManager!.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _stopTimerOnExit();
    }
  }

  bool _startupDone = false;

  void _applyStartupSettings() {
    if (_startupDone) return;
    _startupDone = true;

    // First launch: if no API key, go to Settings
    ref.read(apiKeyProvider.future).then((key) {
      if (key == null && mounted) {
        setState(() => _pageIndex = 2); // Settings tab
      }
    });

  }

  void _stopTimerOnExit() {
    final repo = ref.read(timeTrackingRepositoryProvider);
    repo.stopTimer();
  }

  @override
  void dispose() {
    _stopTimerOnExit();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    WidgetsBinding.instance.removeObserver(this);
    _trayManager?.dispose();
    _notificationService?.dispose();
    _syncService?.dispose();
    super.dispose();
  }

  void _initHotkey() {
    if (_hotkeyInitialized) return;
    _hotkeyInitialized = true;

    HotkeyService.init(onHotkeyPressed: () {
      // Bring window to front, switch to timer, focus search
      HotkeyService.bringToFront();
      // Read hotkey filter preference
      ref.read(settingsDaoProvider).getValue(SettingsKeys.hotkeyFilter).then((val) {
        _hotkeyFilterNotifier.value = val ?? 'myIssues';
      });
      setState(() => _pageIndex = 0);
      // Delay focus until after the tab switch renders
      Future.delayed(const Duration(milliseconds: 100), () {
        _searchFocusNotifier.value++;
      });
    });

    // Register saved hotkey
    ref.read(settingsDaoProvider).getValue(SettingsKeys.globalHotkey).then((val) {
      if (val != null && val.isNotEmpty) {
        final combo = HotkeyCombo.fromString(val);
        HotkeyService.setHotkey(
            keyCode: combo.keyCode, modifiers: combo.modifiers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trigger sync on launch (no-op if not connected)
    ref.watch(syncIssuesProvider);
    // Keep time format in sync
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    if (settings != null) TimeFormat.current = settings.timeDisplayFormat;
    _initNotifications(); // Must be first — sets unified method channel handler
    _initHotkey();
    _initTray();
    _initSync();
    _applyStartupSettings();

    final brightness = MacosTheme.of(context).brightness;

    return MacosWindow(
      titleBar: TitleBar(
        height: 52,
        centerTitle: false,
        title: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabButton(
                    icon: CupertinoIcons.timer,
                    label: 'Timer',
                    isActive: _pageIndex == 0,
                    brightness: brightness,
                    onTap: () => setState(() => _pageIndex = 0),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    icon: CupertinoIcons.chart_bar_square,
                    label: 'History',
                    isActive: _pageIndex == 1,
                    brightness: brightness,
                    onTap: () => setState(() => _pageIndex = 1),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    icon: CupertinoIcons.gear_alt,
                    label: 'Settings',
                    isActive: _pageIndex == 2,
                    brightness: brightness,
                    onTap: () => setState(() => _pageIndex = 2),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SnoozeIndicator(
                  brightness: brightness,
                  onUnsnooze: () {
                    NotificationService.instance?.unsnooze();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _pageIndex,
              children: [
                TimerScreen(
                  searchFocusNotifier: _searchFocusNotifier,
                  hotkeyFilterNotifier: _hotkeyFilterNotifier,
                  filterModeNotifier: _filterModeNotifier,
                ),
                const HistoryScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.brightness,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppColors.accent
        : _hovering
            ? AppColors.textPrimary(widget.brightness)
            : AppColors.textSecondary(widget.brightness);

    final bgColor = widget.isActive
        ? AppColors.accent.withValues(alpha: 0.1)
        : _hovering
            ? AppColors.hover(widget.brightness)
            : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnoozeIndicator extends StatefulWidget {
  const _SnoozeIndicator({
    required this.brightness,
    required this.onUnsnooze,
  });

  final Brightness brightness;
  final VoidCallback onUnsnooze;

  @override
  State<_SnoozeIndicator> createState() => _SnoozeIndicatorState();
}

class _SnoozeIndicatorState extends State<_SnoozeIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update when snooze expires
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // Update immediately when snooze state changes
    NotificationService.instance?.snoozeNotifier.addListener(_onSnoozeChanged);
  }

  void _onSnoozeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    NotificationService.instance?.snoozeNotifier.removeListener(_onSnoozeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ns = NotificationService.instance;
    if (ns == null || !ns.isSnoozed) return const SizedBox.shrink();

    final until = ns.snoozedUntil!;
    final isIndefinite = until.year >= 2099;
    final label = isIndefinite
        ? 'Snoozed'
        : 'Snoozed until ${DateFormat('h:mm a').format(until)}';

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.bell_slash_fill,
                size: 12,
                color: AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onUnsnooze,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 14,
                    color: AppColors.warning.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
