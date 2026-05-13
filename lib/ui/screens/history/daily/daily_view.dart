import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../providers/report_providers.dart';
import '../../../../providers/database_providers.dart';
import '../../../../providers/repository_providers.dart';
import '../../../../providers/settings_providers.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/time_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/open_in_linear.dart';
import 'widgets/time_entry_dialog.dart';

class DailyView extends ConsumerStatefulWidget {
  const DailyView({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends ConsumerState<DailyView> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  }

  @override
  void didUpdateWidget(DailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = DateTime(
          widget.initialDate!.year,
          widget.initialDate!.month,
          widget.initialDate!.day,
        );
      });
    }
  }

  void _previousDay() {
    setState(
        () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDay() {
    setState(
        () => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _deleteEntry(int id) async {
    final dao = ref.read(timeEntryDaoProvider);
    await dao.deleteEntry(id);
    ref.invalidate(dailyEntriesProvider(_selectedDate));
  }

  Future<void> _editEntry(TimeEntry entry) async {
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: _selectedDate,
        existingEntry: entry,
      ),
    );
    if (result == true) {
      ref.invalidate(dailyEntriesProvider(_selectedDate));
    }
  }

  Future<void> _addManualEntry({int? startHour, int? startMinute, int? endHour, int? endMinute}) async {
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: _selectedDate,
        prefilledStartHour: startHour,
        prefilledStartMinute: startMinute,
        prefilledEndHour: endHour,
        prefilledEndMinute: endMinute,
      ),
    );
    if (result == true) {
      ref.invalidate(dailyEntriesProvider(_selectedDate));
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final entries = ref.watch(dailyEntriesProvider(_selectedDate));
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const AppSettings();
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    // Compute total (includes running timer)
    final totalSeconds = entries.valueOrNull
            ?.fold<int>(
                0,
                (sum, e) =>
                    sum +
                    (e.durationSeconds ??
                        (e.endTime ?? DateTime.now())
                            .difference(e.startTime)
                            .inSeconds)) ??
        0;

    return Column(
      children: [
        // Date navigator with total
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
                    onPressed: _previousDay,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(brightness),
                        ),
                      ),
                      if (_isToday)
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.chevron_right),
                    onPressed: _nextDay,
                  ),
                ],
              ),
              if (!_isToday)
                Positioned(
                  left: 0,
                  child: PushButton(
                    controlSize: ControlSize.small,
                    secondary: true,
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() => _selectedDate =
                          DateTime(now.year, now.month, now.day));
                    },
                    child: const Text('Today'),
                  ),
                ),
              if (totalSeconds > 0)
                Positioned(
                  right: 0,
                  child: Text(
                    Duration(seconds: totalSeconds).formatted(TimeFormat.current),
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
          child: entries.when(
            data: (entryList) {
              if (entryList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No time tracked on this day',
                        style: TextStyle(
                            color: AppColors.textSecondary(brightness)),
                      ),
                      const SizedBox(height: 12),
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: () => _addManualEntry(),
                        child: const Text('Add Manual Entry'),
                      ),
                    ],
                  ),
                );
              }
              return _DayTimeline(
                entries: entryList,
                settings: settings,
                brightness: brightness,
                isToday: _isToday,
                onTapEntry: (entry) {
                  if (entry.endTime == null) return;
                  _editEntry(entry);
                },
                onTapEmpty: (startMin, endMin) {
                  _addManualEntry(
                    startHour: startMin ~/ 60,
                    startMinute: startMin % 60,
                    endHour: endMin ~/ 60,
                    endMinute: endMin % 60,
                  );
                },
                onDeleteEntry: (entry) async {
                  if (entry.endTime == null) {
                    final confirm = await showMacosAlertDialog<bool>(
                      context: context,
                      builder: (ctx) => MacosAlertDialog(
                        appIcon: const Icon(CupertinoIcons.trash, size: 48, color: AppColors.danger),
                        title: const Text('Delete running timer?'),
                        message: const Text('This will stop the timer and delete the entry. This cannot be undone.'),
                        primaryButton: PushButton(
                          controlSize: ControlSize.large,
                          color: AppColors.danger,
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Stop & Delete'),
                        ),
                        secondaryButton: PushButton(
                          controlSize: ControlSize.large,
                          secondary: true,
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                    );
                    if (confirm != true) return;
                    final repo = ref.read(timeTrackingRepositoryProvider);
                    repo.stopTimer();
                  }
                  _deleteEntry(entry.id);
                },
              );
            },
            loading: () => const Center(child: ProgressCircle()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

/// Single-day timeline with hour grid, entry blocks, and hover interactions.
class _DayTimeline extends StatefulWidget {
  const _DayTimeline({
    required this.entries,
    required this.settings,
    required this.brightness,
    required this.isToday,
    this.onTapEntry,
    this.onTapEmpty,
    this.onDeleteEntry,
  });

  final List<TimeEntry> entries;
  final AppSettings settings;
  final Brightness brightness;
  final bool isToday;
  final ValueChanged<TimeEntry>? onTapEntry;
  final void Function(int startMin, int endMin)? onTapEmpty;
  final ValueChanged<TimeEntry>? onDeleteEntry;

  @override
  State<_DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<_DayTimeline> {
  double? _hoverY;
  double _columnHeight = 1;
  TimeEntry? _hoveredEntry;

  int get _minHour => _hourRange.$1;
  int get _maxHour => _hourRange.$2;
  int get _totalMinutes => (_maxHour - _minHour) * 60;

  late (int, int) _hourRange;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hourRange = _computeHourRange();
  }

  @override
  void didUpdateWidget(_DayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hourRange = _computeHourRange();
  }

  (int, int) _computeHourRange() {
    var minH = widget.settings.officeStartHour;
    var maxH = widget.settings.officeEndHour;
    for (final entry in widget.entries) {
      final startH = entry.startTime.hour;
      final end = entry.endTime ?? DateTime.now();
      final endH = end.minute > 0 ? end.hour + 1 : end.hour;
      if (startH < minH) minH = startH;
      if (endH > maxH) maxH = endH;
    }
    return (minH.clamp(0, 23), maxH.clamp(minH + 1, 24));
  }

  TimeEntry? _entryAtY(double y) {
    for (final entry in widget.entries) {
      final startMin = entry.startTime.hour * 60 +
          entry.startTime.minute - _minHour * 60;
      final end = entry.endTime ?? DateTime.now();
      final endMin = end.hour * 60 + end.minute - _minHour * 60;
      final top = startMin / _totalMinutes * _columnHeight;
      final bottom = endMin / _totalMinutes * _columnHeight;
      if (y >= top && y <= bottom) return entry;
    }
    return null;
  }

  static const _slotMinutes = 15;

  (int, int) _slotAtY(double y) {
    final minuteOffset = (y / _columnHeight * _totalMinutes).round();
    final snapped = (minuteOffset ~/ _slotMinutes) * _slotMinutes;
    final startMin = _minHour * 60 + snapped;
    final endMin = startMin + _slotMinutes;
    return (startMin, endMin);
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _maxHour - _minHour;
    final brightness = widget.brightness;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hour labels
          SizedBox(
            width: 44,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(totalHours + 1, (i) {
                      final hour = _minHour + i;
                      if (hour > 23) return const SizedBox.shrink();
                      final adjustedHeight = height - 12;
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
                );
              },
            ),
          ),
          // Timeline column
          Expanded(
            child: LayoutBuilder(
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
                        widget.onTapEmpty?.call(slot.$1, slot.$2);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface(brightness),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isToday
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.border(brightness),
                          width: widget.isToday ? 1.0 : 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3.5),
                        child: Stack(
                          children: [
                            // Hour grid lines
                            ...List.generate(totalHours - 1, (i) {
                              final y = (i + 1) / totalHours * height;
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
                            // Hover preview (ghost block)
                            if (_hoverY != null && _entryAtY(_hoverY!) == null)
                              _buildHoverPreview(height),
                            // Entry blocks
                            ...widget.entries.map((entry) {
                              final isRunning = entry.endTime == null;
                              final startMin = entry.startTime.hour * 60 +
                                  entry.startTime.minute - _minHour * 60;
                              final end = entry.endTime ?? DateTime.now();
                              final endMin = end.hour * 60 +
                                  end.minute - _minHour * 60;

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
                                child: _EntryBlock(
                                  entry: entry,
                                  blockHeight: blockHeight,
                                  isHovered: isHovered,
                                  isRunning: isRunning,
                                  baseColor: baseColor,
                                  brightness: brightness,
                                  onDelete: widget.onDeleteEntry != null
                                      ? () => widget.onDeleteEntry!(entry)
                                      : null,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverPreview(double height) {
    final hoverMin = (_hoverY! / height * _totalMinutes).round();
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

/// A single entry block in the timeline with inline details.
class _EntryBlock extends StatelessWidget {
  const _EntryBlock({
    required this.entry,
    required this.blockHeight,
    required this.isHovered,
    required this.isRunning,
    required this.baseColor,
    required this.brightness,
    this.onDelete,
  });

  final TimeEntry entry;
  final double blockHeight;
  final bool isHovered;
  final bool isRunning;
  final Color baseColor;
  final Brightness brightness;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final duration = isRunning
        ? DateTime.now().difference(entry.startTime)
        : Duration(
            seconds: entry.durationSeconds ??
                entry.endTime!.difference(entry.startTime).inSeconds);

    return Container(
      decoration: BoxDecoration(
        color: isRunning
            ? baseColor.withValues(alpha: 0.6)
            : isHovered
                ? baseColor
                : baseColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(2),
        border: isHovered
            ? Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                width: 1,
              )
            : isRunning
                ? Border.all(color: baseColor, width: 1)
                : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Stack(
        children: [
          // Green dot for running entry
          if (isRunning)
            Positioned(
              top: 2,
              left: 0,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Content
          if (blockHeight >= 40)
            _buildTwoLineContent(timeFormat, duration)
          else if (blockHeight >= 20)
            _buildSingleLineContent(timeFormat, duration)
          else if (blockHeight >= 12)
            Center(
              child: Text(
                entry.issueIdentifier,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoLineContent(DateFormat timeFormat, Duration duration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Line 1: ID + title
        Row(
          children: [
            if (isRunning) const SizedBox(width: 10),
            Text(
              entry.issueIdentifier,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entry.issueTitle,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Line 2: time range + duration + badges + actions
        Row(
          children: [
            if (isRunning) const SizedBox(width: 10),
            Text(
              isRunning
                  ? '${timeFormat.format(entry.startTime)} – now'
                  : '${timeFormat.format(entry.startTime)} – ${timeFormat.format(entry.endTime!)}',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              duration.formatted(TimeFormat.current),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (entry.isManual) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Manual',
                  style: TextStyle(
                    fontSize: 8,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Hover actions
            if (isHovered) ...[
              if (!isRunning)
                GestureDetector(
                  onTap: () => openInLinear(identifier: entry.issueIdentifier),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      CupertinoIcons.arrow_up_right_square,
                      size: 12,
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 12,
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSingleLineContent(DateFormat timeFormat, Duration duration) {
    return Row(
      children: [
        if (isRunning) const SizedBox(width: 10),
        Text(
          entry.issueIdentifier,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            entry.issueTitle,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          duration.formatted(TimeFormat.current),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
