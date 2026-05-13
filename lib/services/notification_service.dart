import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../providers/timer_providers.dart';
import 'hotkey_service.dart';
import '../ui/tray/tray_manager.dart';
import '../providers/settings_providers.dart';
import '../providers/repository_providers.dart';
import '../core/constants.dart';
import '../core/extensions/duration_extensions.dart';
import '../core/time_format.dart';
import '../providers/database_providers.dart';

/// Manages idle detection and forgotten timer notifications.
class NotificationService {
  NotificationService(this._ref);

  static NotificationService? instance;
  final WidgetRef _ref;
  static const _channel = MethodChannel('com.lineartime/system');
  Timer? _checkTimer;
  bool _initialized = false;
  DateTime? _lastIdleNotification;
  DateTime? _lastForgottenNotification;
  static const _notificationCooldown = Duration(minutes: 5);
  DateTime? _lastTimerStopTime;
  DateTime? _idleStartTime;

  /// Snooze state — null or in the past means not snoozed.
  DateTime? _snoozedUntil;

  /// Notifies listeners when snooze state changes.
  final snoozeNotifier = ValueNotifier<int>(0);

  /// Whether notifications are currently snoozed.
  bool get isSnoozed =>
      _snoozedUntil != null && DateTime.now().isBefore(_snoozedUntil!);

  /// When the snooze expires, or null if not snoozed.
  DateTime? get snoozedUntil => isSnoozed ? _snoozedUntil : null;

  /// Snooze for a duration. Pass null for indefinite (until manually unsnoozed).
  void snooze([Duration? duration]) {
    if (duration != null) {
      _snoozedUntil = DateTime.now().add(duration);
    } else {
      // Far future = indefinite
      _snoozedUntil = DateTime(2099);
    }
    _persistSnooze();
    snoozeNotifier.value++;
    TrayManager.instance?.updateMenu();
  }

  /// Cancel snooze.
  void unsnooze() {
    _snoozedUntil = null;
    _persistSnooze();
    snoozeNotifier.value++;
    TrayManager.instance?.updateMenu();
  }

  void _persistSnooze() {
    final dao = _ref.read(settingsDaoProvider);
    if (_snoozedUntil != null) {
      dao.setValue(SettingsKeys.snoozedUntil, _snoozedUntil!.toIso8601String());
    } else {
      dao.setValue(SettingsKeys.snoozedUntil, '');
    }
  }

  Future<void> _loadSnooze() async {
    final dao = _ref.read(settingsDaoProvider);
    final val = await dao.getValue(SettingsKeys.snoozedUntil);
    if (val != null && val.isNotEmpty) {
      final dt = DateTime.tryParse(val);
      if (dt != null && dt.isAfter(DateTime.now())) {
        _snoozedUntil = dt;
        snoozeNotifier.value++;
      } else {
        // Expired — clear it
        dao.setValue(SettingsKeys.snoozedUntil, '');
      }
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load persisted snooze state
    await _loadSnooze();

    // Request notification permission
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      // Permission error
    }

    // Unified method call handler for all native → Flutter events
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOverlayResponse') {
        _handleOverlayResponse(call.arguments as String);
      } else {
        // Forward to hotkey service
        HotkeyService.handleMethodCall(call);
      }
    });

    // Check every 30 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _check(),
    );
  }

  Future<void> _check() async {
    final settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings == null) return;
    if (isSnoozed) return;

    if (settings.officeHoursEnabled && !_isInOfficeHours(settings)) return;

    final activeTimer = _ref.read(activeTimerProvider).valueOrNull;

    // Idle detection
    if (settings.idleDetectionEnabled && activeTimer != null) {
      await _checkIdle(settings);
    } else {
      _lastIdleNotification = null;
      _idleStartTime = null;
    }

    // Forgotten timer
    if (settings.forgottenTimerEnabled && activeTimer == null) {
      _checkForgottenTimer(settings);
    } else {
      _lastForgottenNotification = null;
      _lastTimerStopTime = null;
    }
  }

  Future<void> _checkIdle(AppSettings settings) async {
    if (_lastIdleNotification != null &&
        DateTime.now().difference(_lastIdleNotification!) < _notificationCooldown) {
      return;
    }

    try {
      final idleSeconds =
          await _channel.invokeMethod<int>('getIdleSeconds') ?? 0;
      final delaySeconds = settings.idleDelayMinutes * 60;

      if (idleSeconds >= delaySeconds) {
        _lastIdleNotification = DateTime.now();
        _idleStartTime = DateTime.now().subtract(Duration(seconds: idleSeconds));

        final idleDur = Duration(seconds: idleSeconds).formatted(TimeFormat.current);

        if (settings.notificationStyle == 'overlay') {
          await _showOverlay(
            title: 'Are you still working?',
            message: 'You\'ve been idle for $idleDur. Timer is still running.',
            actions: [
              'Keep all time',
              'Trim idle time',
              'Stop timer',
              'Snooze 30m',
              'Snooze 1h',
            ],
          );
        } else {
          await _sendNotification(
            title: 'Are you still working?',
            body: 'You\'ve been idle for $idleDur. Timer is still running.',
            id: 'idle',
          );
        }
      }
    } catch (_) {}
  }

  void _checkForgottenTimer(AppSettings settings) {
    if (_lastForgottenNotification != null &&
        DateTime.now().difference(_lastForgottenNotification!) < _notificationCooldown) {
      return;
    }

    _lastTimerStopTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_lastTimerStopTime!);
    if (elapsed.inMinutes >= settings.forgottenTimerDelayMinutes) {
      _lastForgottenNotification = DateTime.now();

      final dur = elapsed.formatted(TimeFormat.current);

      if (settings.notificationStyle == 'overlay') {
        _showOverlay(
          title: 'Did you forget your timer?',
          message: 'No timer has been running for $dur.',
          actions: [
            'Open Linear Time',
            'Snooze 30m',
            'Snooze 1h',
            'Dismiss',
          ],
        );
      } else {
        _sendNotification(
          title: 'Did you forget your timer?',
          body: 'No timer has been running for $dur.',
          id: 'forgotten',
        );
      }
    }
  }

  void _handleOverlayResponse(String action) {
    switch (action) {
      case 'Keep all time':
        // Do nothing — timer keeps running
        break;
      case 'Trim idle time':
        // Stop timer at when idle started, then restart
        if (_idleStartTime != null) {
          final repo = _ref.read(timeTrackingRepositoryProvider);
          final active = _ref.read(activeTimerProvider).valueOrNull;
          if (active != null) {
            // Stop at idle start time and restart now
            repo.stopTimer();
            // The entry will have endTime = now, but we want idleStartTime
            // We'll adjust via the DAO
            _ref.read(timeTrackingRepositoryProvider).timeEntryDao
                .getEntriesForDay(DateTime.now())
                .then((entries) {
              final last = entries.where((e) => e.issueId == active.issueId).lastOrNull;
              if (last != null && _idleStartTime != null) {
                final duration = _idleStartTime!.difference(last.startTime).inSeconds;
                repo.timeEntryDao.updateEntry(
                  last.id,
                  TimeEntriesCompanion(
                    endTime: drift.Value(_idleStartTime!),
                    durationSeconds: drift.Value(duration),
                  ),
                );
              }
            });
          }
        }
        break;
      case 'Stop timer':
        final repo = _ref.read(timeTrackingRepositoryProvider);
        repo.stopTimer();
        break;
      case 'Open Linear Time':
        _channel.invokeMethod('bringToFront');
        break;
      case 'Snooze 30m':
        snooze(const Duration(minutes: 30));
        break;
      case 'Snooze 1h':
        snooze(const Duration(hours: 1));
        break;
      case 'Dismiss':
        // Do nothing
        break;
    }
    _idleStartTime = null;
  }

  bool _isInOfficeHours(AppSettings settings) {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    if (!settings.officeDays.contains(weekday)) return false;
    return hour >= settings.officeStartHour && hour < settings.officeEndHour;
  }

  Future<void> _showOverlay({
    required String title,
    required String message,
    required List<String> actions,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'title': title,
        'message': message,
        'actions': actions,
      });
    } catch (_) {}
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required String id,
  }) async {
    try {
      await _channel.invokeMethod('sendNotification', {
        'title': title,
        'body': body,
        'id': id,
      });
    } catch (_) {}
  }

  void onTimerStateChanged() {
    _lastForgottenNotification = null;
    _lastIdleNotification = null;
    _lastTimerStopTime = null;
    _idleStartTime = null;
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
