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

  Future<void> _onTapEntry(DateTime date, TimeEntry entry) async {
    final day = DateTime(date.year, date.month, date.day);
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: day,
        existingEntry: entry,
      ),
    );
    if (result == true) {
      ref.invalidate(weeklyEntriesProvider(_weekStart));
      ref.invalidate(weeklySummaryProvider(_weekStart));
      ref.invalidate(dailyEntriesProvider(day));
    }
  }

  Future<void> _onTapEmpty(DateTime date, int startMin, int endMin) async {
    final day = DateTime(date.year, date.month, date.day);
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: day,
        prefilledStartHour: startMin ~/ 60,
        prefilledStartMinute: startMin % 60,
        prefilledEndHour: endMin ~/ 60,
        prefilledEndMinute: endMin % 60,
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
            onTapEntry: _onTapEntry,
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
    this.onTapEntry,
  });

  final DateTime weekStart;
  final AppSettings settings;
  final Brightness brightness;
  /// Called with (date, startMinuteOfDay, endMinuteOfDay) when clicking empty space.
  final void Function(DateTime date, int startMin, int endMin)? onTapEmpty;
  final void Function(DateTime date, TimeEntry entry)? onTapEntry;

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
                        onTapSlot: onTapEmpty != null
                            ? (startMin, endMin) =>
                                onTapEmpty!(day, startMin, endMin)
                            : null,
                        onTapEntry: onTapEntry != null
                            ? (entry) => onTapEntry!(day, entry)
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

/// A single day column with hour grid lines, entry blocks, hover preview, and click handling.
class _DayColumn extends StatefulWidget {
  const _DayColumn({
    required this.entries,
    required this.minHour,
    required this.maxHour,
    required this.isToday,
    required this.brightness,
    this.onTapSlot,
    this.onTapEntry,
  });

  final List<TimeEntry> entries;
  final int minHour;
  final int maxHour;
  final bool isToday;
  final Brightness brightness;
  /// Called with (startMinuteOfDay, endMinuteOfDay) when clicking empty space.
  final void Function(int startMin, int endMin)? onTapSlot;
  final ValueChanged<TimeEntry>? onTapEntry;

  @override
  State<_DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends State<_DayColumn> {
  double? _hoverY;
  double _columnHeight = 1;
  TimeEntry? _hoveredEntry;

  int get _totalMinutes => (widget.maxHour - widget.minHour) * 60;

  /// Find entry at a given Y position, or null if empty space.
  TimeEntry? _entryAtY(double y) {
    for (final entry in widget.entries) {
      if (entry.endTime == null) continue;
      final startMin = entry.startTime.hour * 60 +
          entry.startTime.minute -
          widget.minHour * 60;
      final endMin = entry.endTime!.hour * 60 +
          entry.endTime!.minute -
          widget.minHour * 60;
      final top = startMin / _totalMinutes * _columnHeight;
      final bottom = endMin / _totalMinutes * _columnHeight;
      if (y >= top && y <= bottom) return entry;
    }
    return null;
  }

  static const _slotMinutes = 15;

  /// Get the snapped slot (start, end) in minutes-of-day at a Y position.
  (int startMin, int endMin) _slotAtY(double y) {
    final minuteOffset =
        (y / _columnHeight * _totalMinutes).round();
    final snapped =
        (minuteOffset ~/ _slotMinutes) * _slotMinutes;
    final startMin = widget.minHour * 60 + snapped;
    final endMin = startMin + _slotMinutes;
    return (startMin, endMin);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _columnHeight = constraints.maxHeight;
        final height = _columnHeight;

        return MouseRegion(
          onHover: (event) => setState(() {
            _hoverY = event.localPosition.dy;
            _hoveredEntry = _entryAtY(_hoverY!);
          }),
          onExit: (_) => setState(() {
            _hoverY = null;
            _hoveredEntry = null;
          }),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapUp: (details) {
              final y = details.localPosition.dy;
              final entry = _entryAtY(y);
              if (entry != null) {
                widget.onTapEntry?.call(entry);
              } else {
                final slot = _slotAtY(y);
                widget.onTapSlot?.call(slot.$1, slot.$2);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(widget.brightness),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.isToday
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.border(widget.brightness),
                  width: widget.isToday ? 1.0 : 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3.5),
                child: Stack(
                  children: [
                    // Hour grid lines
                    ...List.generate(widget.maxHour - widget.minHour - 1, (i) {
                      final y = (i + 1) / (widget.maxHour - widget.minHour) * height;
                      return Positioned(
                        top: y,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 0.5,
                          color: AppColors.border(widget.brightness)
                              .withValues(alpha: 0.5),
                        ),
                      );
                    }),
                    // Hover preview (ghost block)
                    if (_hoverY != null && _entryAtY(_hoverY!) == null)
                      _buildHoverPreview(height),
                    // Completed entry blocks
                    ...widget.entries.where((e) => e.endTime != null).map((entry) {
                      final startMin = entry.startTime.hour * 60 +
                          entry.startTime.minute -
                          widget.minHour * 60;
                      final endMin = entry.endTime!.hour * 60 +
                          entry.endTime!.minute -
                          widget.minHour * 60;

                      final top = (startMin / _totalMinutes * height)
                          .clamp(0.0, height);
                      final bottom = (endMin / _totalMinutes * height)
                          .clamp(0.0, height);
                      final blockHeight = (bottom - top).clamp(2.0, height);
                      final isHovered = _hoveredEntry?.id == entry.id;
                      final baseColor = AppColors.colorForIssue(entry.issueId);

                      return Positioned(
                        top: top,
                        left: 1,
                        right: 1,
                        height: blockHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isHovered
                                ? baseColor
                                : baseColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(2),
                            border: isHovered
                                ? Border.all(
                                    color: const Color(0xFFFFFFFF)
                                        .withValues(alpha: 0.5),
                                    width: 1)
                                : null,
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
                    ...widget.entries.where((e) => e.endTime == null).map((entry) {
                      final startMin = entry.startTime.hour * 60 +
                          entry.startTime.minute -
                          widget.minHour * 60;
                      final now = DateTime.now();
                      final endMin =
                          now.hour * 60 + now.minute - widget.minHour * 60;

                      final top = (startMin / _totalMinutes * height)
                          .clamp(0.0, height);
                      final bottom = (endMin / _totalMinutes * height)
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
          ),
        );
      },
    );
  }

  Widget _buildHoverPreview(double height) {
    final hoverMin =
        (_hoverY! / height * _totalMinutes).round();
    final snappedMin = (hoverMin ~/ _slotMinutes) * _slotMinutes;
    final top = (snappedMin / _totalMinutes * height).clamp(0.0, height);
    final bottom =
        ((snappedMin + _slotMinutes) / _totalMinutes * height).clamp(0.0, height);
    final blockHeight = (bottom - top).clamp(2.0, height);

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: blockHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.plus,
          size: 10,
          color: AppColors.accent.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
