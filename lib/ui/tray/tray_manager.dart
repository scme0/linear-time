import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_tray/system_tray.dart';

import '../../providers/timer_providers.dart';
import '../../providers/issue_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/database_providers.dart';
import '../../core/constants.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../core/time_format.dart';
import '../../services/hotkey_service.dart';

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

    // Presentation mode toggle
    final settings = _ref.read(appSettingsProvider).valueOrNull;
    final presentationMode = settings?.presentationMode ?? false;
    menuItems.add(MenuItem(
      label: presentationMode ? '● Presentation Mode (on)' : 'Presentation Mode',
      onClicked: () async {
        final dao = _ref.read(settingsDaoProvider);
        await dao.setValue(SettingsKeys.presentationMode, (!presentationMode).toString());
        _ref.invalidate(appSettingsProvider);
        updateMenu();
      },
    ));
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
    if (activeEntry != null) {
      final elapsed = DateTime.now().difference(activeEntry.startTime);
      await _systemTray.setTitle(
          '${activeEntry.issueIdentifier} ${elapsed.formatted(TimeFormat.current)}');
      await _systemTray.setToolTip(
          'Linear Time — ${activeEntry.issueIdentifier} ${elapsed.formatted(TimeFormat.current)}');
    } else {
      await _systemTray.setTitle('');
      await _systemTray.setToolTip('Linear Time');
    }
  }

  void dispose() {
    _menuTimer?.cancel();
    _titleTimer?.cancel();
  }
}
