import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_tray/system_tray.dart';

import '../../providers/timer_providers.dart';
import '../../providers/issue_providers.dart';
import '../../providers/repository_providers.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../services/hotkey_service.dart';

/// Manages the system tray icon and menu.
class TrayManager {
  TrayManager(this._ref);

  final WidgetRef _ref;
  final _systemTray = SystemTray();
  Timer? _updateTimer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _systemTray.initSystemTray(
      title: '',
      iconPath: 'assets/icons/tray_icon.png',
      toolTip: 'Linear Time',
    );

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == 'leftMouseUp') {
        HotkeyService.bringToFront();
      } else if (eventName == 'rightMouseUp') {
        _systemTray.popUpContextMenu();
      }
    });

    await _updateMenu();

    // Update menu every 5 seconds to refresh timer display
    _updateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateMenu(),
    );
  }

  Future<void> _updateMenu() async {
    final activeEntry = _ref.read(activeTimerProvider).valueOrNull;
    final recentEntries =
        await _ref.read(recentTrackedIssuesProvider.future);

    final menuItems = <MenuItemBase>[];

    // Current timer status
    if (activeEntry != null) {
      final elapsed =
          DateTime.now().difference(activeEntry.startTime);
      menuItems.add(MenuItem(
        label: '${activeEntry.issueIdentifier}: ${activeEntry.issueTitle}',
        enabled: false,
      ));
      menuItems.add(MenuItem(
        label: '  ${elapsed.toHms()}',
        enabled: false,
      ));
      menuItems.add(MenuItem(
        label: 'Stop Timer',
        onClicked: () {
          final repo = _ref.read(timeTrackingRepositoryProvider);
          repo.stopTimer();
          _ref.invalidate(recentTrackedIssuesProvider);
          _updateMenu();
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
            _updateMenu();
          },
        ));
      }
      menuItems.add(MenuSeparator());
    }

    // Navigation
    menuItems.add(MenuItem(
      label: 'Choose Another Issue...',
      onClicked: () => HotkeyService.bringToFront(),
    ));
    menuItems.add(MenuSeparator());

    // Quit
    menuItems.add(MenuItem(
      label: 'Quit Linear Time',
      onClicked: () => exit(0),
    ));

    await _systemTray.setContextMenu(menuItems);

    // Update menubar title + tooltip
    if (activeEntry != null) {
      final elapsed =
          DateTime.now().difference(activeEntry.startTime);
      await _systemTray.setTitle(
          '${activeEntry.issueIdentifier} ${elapsed.toHms()}');
      await _systemTray.setToolTip(
          'Linear Time — ${activeEntry.issueIdentifier} ${elapsed.toHms()}');
    } else {
      await _systemTray.setTitle('');
      await _systemTray.setToolTip('Linear Time');
    }
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
