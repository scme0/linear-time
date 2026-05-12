import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../providers/report_providers.dart';
import '../../../../providers/settings_providers.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../daily/widgets/time_entry_dialog.dart';

class WeeklyView extends ConsumerStatefulWidget {
  const WeeklyView({super.key});

  @override
  ConsumerState<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends ConsumerState<WeeklyView> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = DateTime.now().startOfWeek;
  }

  void _previousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  bool get _isCurrentWeek => _weekStart == DateTime.now().startOfWeek;

  Future<void> _onTapEmpty(DateTime date, int hour) async {
    final day = DateTime(date.year, date.month, date.day);
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: day,
        prefilledStartHour: hour,
      ),
    );
    if (result == true) {
      ref.invalidate(weeklyEntriesProvider(_weekStart));
      ref.invalidate(weeklySummaryProvider(_weekStart));
      ref.invalidate(dailyEntriesProvider(day));
    }
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weeklySummaryProvider(_weekStart));
    final settingsAsync = ref.watch(appSettingsProvider);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    final weekLabel =
        '${dateFormat.format(_weekStart)} – ${dateFormat.format(weekEnd)}, ${weekEnd.year}';
    final brightness = MacosTheme.of(context).brightness;

    final settings = settingsAsync.valueOrNull ?? const AppSettings();

    return Column(
      children: [
        // Week navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.chevron_left),
                    onPressed: _previousWeek,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    weekLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.chevron_right),
                    onPressed: _nextWeek,
                  ),
                ],
              ),
              if (!_isCurrentWeek)
                Positioned(
                  left: 0,
                  child: PushButton(
                    controlSize: ControlSize.small,
                    secondary: true,
                    onPressed: () {
                      setState(() => _weekStart = DateTime.now().startOfWeek);
                    },
                    child: const Text('This Week'),
                  ),
                ),
              if ((summary.valueOrNull?.grandTotalSeconds ?? 0) > 0)
                Positioned(
                  right: 0,
                  child: Text(
                    Duration(seconds: summary.valueOrNull!.grandTotalSeconds)
                        .toHumanReadable(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Timeline
        Expanded(
          child: _WeekTimeline(
            weekStart: _weekStart,
            settings: settings,
            brightness: brightness,
            onTapEmpty: _onTapEmpty,
          ),
        ),
        // Issue legend + grand total
        summary.when(
          data: (data) {
            if (data.issues.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: AppColors.border(brightness), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  // Issue legend
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: data.issues.map((issue) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.colorForIssue(issue.issueId),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${issue.identifier} ${Duration(seconds: issue.totalSeconds).toHumanReadable()}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary(brightness),
                              ),
                            ),
                          ],
                        );
                      }).toList()
                        ..add(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total: ${Duration(seconds: data.grandTotalSeconds).toHumanReadable()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(brightness),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The main timeline widget showing day columns with hour lines and entry blocks.
class _WeekTimeline extends ConsumerWidget {
  const _WeekTimeline({
    required this.weekStart,
    required this.settings,
    required this.brightness,
    this.onTapEmpty,
  });

  final DateTime weekStart;
  final AppSettings settings;
  final Brightness brightness;
  final void Function(DateTime date, int hour)? onTapEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load all 7 days of entries
    final allDayEntries = <int, List<TimeEntry>>{};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final entriesAsync = ref.watch(dailyEntriesProvider(day));
      allDayEntries[i] = entriesAsync.valueOrNull ?? [];
    }

    // Determine which days to show:
    // - Office days from settings
    // - Any day that has entries this week
    final officeDays = settings.officeDays; // 1=Mon, 7=Sun
    final visibleDays = <int>[]; // 0-indexed (0=Mon)
    for (var i = 0; i < 7; i++) {
      final dayNum = i + 1; // 1=Mon
      final hasEntries = allDayEntries[i]?.isNotEmpty ?? false;
      if (officeDays.contains(dayNum) || hasEntries) {
        visibleDays.add(i);
      }
    }
    if (visibleDays.isEmpty) {
      visibleDays.addAll([0, 1, 2, 3, 4]); // default Mon-Fri
    }

    // Determine hour range: default office hours, expand if entries go outside
    var minHour = settings.officeStartHour;
    var maxHour = settings.officeEndHour;
    for (final i in visibleDays) {
      for (final entry in allDayEntries[i] ?? <TimeEntry>[]) {
        final startH = entry.startTime.hour;
        final endH = entry.endTime != null
            ? (entry.endTime!.minute > 0
                ? entry.endTime!.hour + 1
                : entry.endTime!.hour)
            : DateTime.now().hour + 1;
        if (startH < minHour) minHour = startH;
        if (endH > maxHour) maxHour = endH;
      }
    }
    // Clamp
    minHour = minHour.clamp(0, 23);
    maxHour = maxHour.clamp(minHour + 1, 24);

    final totalHours = maxHour - minHour;
    final dayFormat = DateFormat('E');
    final dayNumFormat = DateFormat('d');

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hour labels column
          SizedBox(
            width: 40,
            child: _HourLabels(
              minHour: minHour,
              totalHours: totalHours,
              brightness: brightness,
            ),
          ),
          // Day columns
          ...visibleDays.map((i) {
            final day = weekStart.add(Duration(days: i));
            final entries = allDayEntries[i] ?? [];
            final isToday = day.isSameDay(DateTime.now());

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    // Day header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          Text(
                            dayFormat.format(day),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? AppColors.accent
                                  : AppColors.textSecondary(brightness),
                            ),
                          ),
                          Text(
                            dayNumFormat.format(day),
                            style: TextStyle(
                              fontSize: 10,
                              color: isToday
                                  ? AppColors.accent
                                  : AppColors.textTertiary(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timeline column
                    Expanded(
                      child: _DayColumn(
                        entries: entries,
                        minHour: minHour,
                        maxHour: maxHour,
                        isToday: isToday,
                        brightness: brightness,
                        onTapHour: onTapEmpty != null
                            ? (hour) => onTapEmpty!(day, hour)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Hour labels on the left side.
class _HourLabels extends StatelessWidget {
  const _HourLabels({
    required this.minHour,
    required this.totalHours,
    required this.brightness,
  });

  final int minHour;
  final int totalHours;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Account for the day header space at top
        const headerHeight = 34.0;
        final timelineHeight = constraints.maxHeight - headerHeight;

        return Column(
          children: [
            const SizedBox(height: headerHeight),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(totalHours + 1, (i) {
                    final hour = minHour + i;
                    if (hour > 23) return const SizedBox.shrink();
                    final adjustedHeight = timelineHeight - 12; // account for padding
                    final y = i / totalHours * adjustedHeight;
                    return Positioned(
                      top: y - 5,
                      left: 0,
                      right: 4,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textTertiary(brightness),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single day column with hour grid lines and entry blocks.
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.entries,
    required this.minHour,
    required this.maxHour,
    required this.isToday,
    required this.brightness,
    this.onTapHour,
  });

  final List<TimeEntry> entries;
  final int minHour;
  final int maxHour;
  final bool isToday;
  final Brightness brightness;
  final ValueChanged<int>? onTapHour;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (maxHour - minHour) * 60;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return GestureDetector(
          onTapUp: onTapHour != null
              ? (details) {
                  final y = details.localPosition.dy;
                  final hour =
                      minHour + (y / height * (maxHour - minHour)).floor();
                  onTapHour!(hour.clamp(minHour, maxHour - 1));
                }
              : null,
          child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isToday
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border(brightness),
              width: isToday ? 1.0 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.5),
            child: Stack(
              children: [
                // Hour grid lines
                ...List.generate(maxHour - minHour - 1, (i) {
                  final y = (i + 1) / (maxHour - minHour) * height;
                  return Positioned(
                    top: y,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 0.5,
                      color: AppColors.border(brightness)
                          .withValues(alpha: 0.5),
                    ),
                  );
                }),
                // Entry blocks
                ...entries.where((e) => e.endTime != null).map((entry) {
                  final startMin = entry.startTime.hour * 60 +
                      entry.startTime.minute -
                      minHour * 60;
                  final endMin = entry.endTime!.hour * 60 +
                      entry.endTime!.minute -
                      minHour * 60;

                  final top = (startMin / totalMinutes * height)
                      .clamp(0.0, height);
                  final bottom = (endMin / totalMinutes * height)
                      .clamp(0.0, height);
                  final blockHeight = (bottom - top).clamp(2.0, height);

                  return Positioned(
                    top: top,
                    left: 1,
                    right: 1,
                    height: blockHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.colorForIssue(entry.issueId)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: blockHeight >= 16
                          ? Text(
                              entry.issueIdentifier,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            )
                          : null,
                    ),
                  );
                }),
                // Currently running entry
                ...entries.where((e) => e.endTime == null).map((entry) {
                  final startMin = entry.startTime.hour * 60 +
                      entry.startTime.minute -
                      minHour * 60;
                  final now = DateTime.now();
                  final endMin =
                      now.hour * 60 + now.minute - minHour * 60;

                  final top = (startMin / totalMinutes * height)
                      .clamp(0.0, height);
                  final bottom = (endMin / totalMinutes * height)
                      .clamp(0.0, height);
                  final blockHeight = (bottom - top).clamp(2.0, height);

                  return Positioned(
                    top: top,
                    left: 1,
                    right: 1,
                    height: blockHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.colorForIssue(entry.issueId)
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppColors.colorForIssue(entry.issueId),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}
