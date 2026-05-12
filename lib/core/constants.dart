/// Linear API endpoint.
const kLinearApiUrl = 'https://api.linear.app/graphql';

/// Default sync interval in minutes.
const kDefaultSyncIntervalMinutes = 5;

/// Default idle detection delay in minutes.
const kDefaultIdleDelayMinutes = 15;

/// Default forgotten timer delay in minutes.
const kDefaultForgottenTimerDelayMinutes = 30;

/// Default office hours.
const kDefaultOfficeStartHour = 9;
const kDefaultOfficeEndHour = 17;

/// Number of recent issues to show in tray menu.
const kRecentIssuesCount = 5;

/// Minimum entry duration in seconds (discard below this).
const kDefaultMinEntryDurationSeconds = 5;

/// Settings keys.
abstract class SettingsKeys {
  static const syncIntervalMinutes = 'sync_interval_minutes';
  static const syncOnLaunch = 'sync_on_launch';
  static const showCompletedIssues = 'show_completed_issues';
  static const idleDetectionEnabled = 'idle_detection_enabled';
  static const idleDelayMinutes = 'idle_delay_minutes';
  static const forgottenTimerEnabled = 'forgotten_timer_enabled';
  static const forgottenTimerDelayMinutes = 'forgotten_timer_delay_minutes';
  static const officeHoursEnabled = 'office_hours_enabled';
  static const officeStartHour = 'office_start_hour';
  static const officeEndHour = 'office_end_hour';
  static const officeDays = 'office_days'; // comma-separated: "1,2,3,4,5"
  static const launchAtLogin = 'launch_at_login';
  static const showInDock = 'show_in_dock';
  static const timeDisplayFormat = 'time_display_format'; // "hms" or "decimal"
  static const minEntryDurationSeconds = 'min_entry_duration_seconds';
  static const themeMode = 'theme_mode'; // "system", "light", "dark"
}
