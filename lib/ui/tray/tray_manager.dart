import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_tray/system_tray.dart';

import '../../providers/timer_providers.dart';
import '../../providers/issue_providers.dart';
import '../../providers/repository_providers.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../core/time_format.dart';
import '../../services/hotkey_service.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';

/// Manages the system tray icon and menu.
class TrayManager {
  TrayManager(this._ref, {this.onNavigate});

  /// Global instance for easy access from other widgets.
  static TrayManager? instance;

  /// Callback to navigate to a specific tab (0=Timer, 1=History, 2=Settings).
  final void Function(int tabIndex)? onNavigate;

  final WidgetRef _ref;
  final _systemTray = SystemTray();
  Timer? _menuTimer;
  Timer? _titleTimer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _systemTray.initSystemTray(
      title: '',
      iconPath: '',
      toolTip: 'Linear Time',
    );

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == 'leftMouseUp') {
        HotkeyService.bringToFront();
      } else if (eventName == 'rightMouseUp') {
        _systemTray.popUpContextMenu();
      }
    });

    await updateMenu();

    // Update menu every 10 seconds (structural changes)
    _menuTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => updateMenu(),
    );

    // Update title every second (cheap — just text)
    _titleTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateTitle(),
    );
  }

  Future<void> updateMenu() async {
    final activeEntry = _ref.read(activeTimerProvider).valueOrNull;
    final recentEntries =
        await _ref.read(recentTrackedIssuesProvider.future);

    final menuItems = <MenuItemBase>[];

    // Current timer status
    if (activeEntry != null) {
      menuItems.add(MenuItem(
        label: '${activeEntry.issueIdentifier}: ${activeEntry.issueTitle}',
        enabled: false,
      ));
      menuItems.add(MenuItem(
        label: 'Stop Timer',
        onClicked: () {
          final repo = _ref.read(timeTrackingRepositoryProvider);
          repo.stopTimer();
          _ref.invalidate(recentTrackedIssuesProvider);
          updateMenu();
        },
      ));
    } else {
      menuItems.add(MenuItem(
        label: 'No active timer',
        enabled: false,
      ));
    }

    menuItems.add(MenuSeparator());

    // Recent issues for quick switch (exclude active)
    final recentFiltered = recentEntries
        .where((e) => activeEntry == null || e.issueId != activeEntry.issueId)
        .take(5);
    if (recentFiltered.isNotEmpty) {
      for (final entry in recentFiltered) {
        menuItems.add(MenuItem(
          label: '${entry.issueIdentifier}: ${entry.issueTitle}',
          onClicked: () {
            final repo = _ref.read(timeTrackingRepositoryProvider);
            repo.startTimer(
              issueId: entry.issueId,
              issueIdentifier: entry.issueIdentifier,
              issueTitle: entry.issueTitle,
              teamName: entry.teamName,
              projectName: entry.projectName,
              teamColor: entry.teamColor,
            );
            _ref.invalidate(recentTrackedIssuesProvider);
            updateMenu();
          },
        ));
      }
      menuItems.add(MenuSeparator());
    }

    // Navigation
    menuItems.add(MenuItem(
      label: 'Choose Another Issue...',
      onClicked: () {
        HotkeyService.bringToFront();
        onNavigate?.call(0);
      },
    ));
    menuItems.add(MenuItem(
      label: 'History',
      onClicked: () {
        HotkeyService.bringToFront();
        onNavigate?.call(1);
      },
    ));
    menuItems.add(MenuItem(
      label: 'Settings',
      onClicked: () {
        HotkeyService.bringToFront();
        onNavigate?.call(2);
      },
    ));
    menuItems.add(MenuSeparator());

    // Snooze submenu
    final ns = NotificationService.instance;
    final snoozed = ns?.isSnoozed ?? false;
    if (snoozed) {
      final until = ns!.snoozedUntil!;
      final isIndefinite = until.year >= 2099;
      final label = isIndefinite
          ? '● Snoozed (until unsnoozed)'
          : '● Snoozed until ${DateFormat('h:mm a').format(until)}';
      menuItems.add(MenuItem(
        label: label,
        enabled: false,
      ));
      menuItems.add(MenuItem(
        label: 'Unsnooze',
        onClicked: () {
          ns.unsnooze();
        },
      ));
    } else {
      menuItems.add(SubMenu(
        label: 'Snooze Notifications',
        children: [
          MenuItem(
            label: '30 minutes',
            onClicked: () => ns?.snooze(const Duration(minutes: 30)),
          ),
          MenuItem(
            label: '1 hour',
            onClicked: () => ns?.snooze(const Duration(hours: 1)),
          ),
          MenuItem(
            label: '2 hours',
            onClicked: () => ns?.snooze(const Duration(hours: 2)),
          ),
          MenuItem(
            label: '4 hours',
            onClicked: () => ns?.snooze(const Duration(hours: 4)),
          ),
          MenuItem(
            label: 'Until I unsnooze',
            onClicked: () => ns?.snooze(),
          ),
        ],
      ));
    }
    menuItems.add(MenuSeparator());

    // Quit
    menuItems.add(MenuItem(
      label: 'Quit Linear Time',
      onClicked: () => exit(0),
    ));

    await _systemTray.setContextMenu(menuItems);

    await updateTitle();
  }

  Future<void> updateTitle() async {
    final activeEntry = _ref.read(activeTimerProvider).valueOrNull;
    final snoozed = NotificationService.instance?.isSnoozed ?? false;
    final prefix = snoozed ? '🔕 ' : '';

    if (activeEntry != null) {
      final elapsed = DateTime.now().difference(activeEntry.startTime);
      await _systemTray.setSystemTrayInfo(
        title: '$prefix${activeEntry.issueIdentifier} ${elapsed.formatted(TimeFormat.current)}',
        iconPath: '',
        toolTip: 'Linear Time — ${activeEntry.issueIdentifier} ${elapsed.formatted(TimeFormat.current)}',
      );
    } else {
      await _systemTray.setSystemTrayInfo(
        title: '${prefix}No Issue',
        iconPath: '',
        toolTip: 'Linear Time',
      );
    }
  }

  void dispose() {
    _menuTimer?.cancel();
    _titleTimer?.cancel();
  }
}
