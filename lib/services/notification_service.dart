import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timer_providers.dart';
import '../providers/settings_providers.dart';

/// Manages idle detection and forgotten timer notifications.
class NotificationService {
  NotificationService(this._ref);

  static NotificationService? instance;
  final WidgetRef _ref;
  static const _channel = MethodChannel('com.lineartime/system');
  Timer? _checkTimer;
  bool _initialized = false;
  bool _idleNotificationSent = false;
  bool _forgottenNotificationSent = false;
  DateTime? _lastTimerStopTime;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permission
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (_) {}

    // Check every 30 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _check(),
    );
  }

  Future<void> _check() async {
    final settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings == null) return;

    // Check office hours
    if (settings.officeHoursEnabled && !_isInOfficeHours(settings)) return;

    final activeTimer = _ref.read(activeTimerProvider).valueOrNull;

    // Idle detection — timer running but user idle
    if (settings.idleDetectionEnabled && activeTimer != null) {
      await _checkIdle(settings.idleDelayMinutes);
    } else {
      _idleNotificationSent = false;
    }

    // Forgotten timer — no timer running during office hours
    if (settings.forgottenTimerEnabled && activeTimer == null) {
      _checkForgottenTimer(settings.forgottenTimerDelayMinutes);
    } else {
      _forgottenNotificationSent = false;
      _lastTimerStopTime = null;
    }
  }

  Future<void> _checkIdle(int delayMinutes) async {
    if (_idleNotificationSent) return;

    try {
      final idleSeconds =
          await _channel.invokeMethod<int>('getIdleSeconds') ?? 0;
      if (idleSeconds >= delayMinutes * 60) {
        _idleNotificationSent = true;
        await _sendNotification(
          title: 'Are you still working?',
          body:
              'You\'ve been idle for $delayMinutes minutes. Timer is still running.',
          id: 'idle',
        );
      }
    } catch (_) {}
  }

  void _checkForgottenTimer(int delayMinutes) {
    if (_forgottenNotificationSent) return;

    _lastTimerStopTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_lastTimerStopTime!);
    if (elapsed.inMinutes >= delayMinutes) {
      _forgottenNotificationSent = true;
      _sendNotification(
        title: 'Did you forget your timer?',
        body:
            'No timer has been running for $delayMinutes minutes.',
        id: 'forgotten',
      );
    }
  }

  bool _isInOfficeHours(AppSettings settings) {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday; // 1=Mon, 7=Sun
    if (!settings.officeDays.contains(weekday)) return false;
    return hour >= settings.officeStartHour && hour < settings.officeEndHour;
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

  /// Call when timer starts/stops to reset forgotten timer tracking.
  void onTimerStateChanged() {
    _forgottenNotificationSent = false;
    _idleNotificationSent = false;
    _lastTimerStopTime = null;
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
