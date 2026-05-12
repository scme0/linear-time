import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../providers/report_providers.dart';
import '../../../../providers/database_providers.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';
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

  Future<void> _addManualEntry() async {
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(date: _selectedDate),
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
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    // Compute total for nav bar
    final totalSeconds = entries.valueOrNull
            ?.where((e) => e.endTime != null)
            .fold<int>(
                0,
                (sum, e) =>
                    sum +
                    (e.durationSeconds ??
                        e.endTime!.difference(e.startTime).inSeconds)) ??
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                    Duration(seconds: totalSeconds).toHumanReadable(),
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
        // Entry list with Add Time at bottom
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
                        onPressed: _addManualEntry,
                        child: const Text('Add Manual Entry'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entryList.length + 1, // +1 for Add Time
                itemBuilder: (context, index) {
                  if (index == entryList.length) {
                    // Add Time button as last list item
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: _addManualEntry,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.border(brightness),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.plus,
                                    size: 14,
                                    color:
                                        AppColors.textSecondary(brightness)),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        AppColors.textSecondary(brightness),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final entry = entryList[index];
                  return _EntryCard(
                    entry: entry,
                    onTap: entry.endTime != null
                        ? () => _editEntry(entry)
                        : null,
                    onDelete: () => _deleteEntry(entry.id),
                  );
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

class _EntryCard extends StatefulWidget {
  const _EntryCard({
    required this.entry,
    this.onTap,
    required this.onDelete,
  });

  final TimeEntry entry;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final timeFormat = DateFormat('HH:mm');
    final isRunning = widget.entry.endTime == null;
    final duration = isRunning
        ? DateTime.now().difference(widget.entry.startTime)
        : Duration(
            seconds: widget.entry.durationSeconds ??
                widget.entry.endTime!
                    .difference(widget.entry.startTime)
                    .inSeconds);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.hover(brightness) : null,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: AppColors.colorForIssue(widget.entry.issueId),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Time range
              SizedBox(
                width: 110,
                child: Text(
                  isRunning
                      ? '${timeFormat.format(widget.entry.startTime)} – now'
                      : '${timeFormat.format(widget.entry.startTime)} – ${timeFormat.format(widget.entry.endTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Issue identifier
              Text(
                widget.entry.issueIdentifier,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              // Issue title
              Expanded(
                child: Text(
                  widget.entry.issueTitle,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Manual badge
              if (widget.entry.isManual)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Manual',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              // Running indicator
              if (isRunning)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              // Edit hint on hover
              if (_hovering && !isRunning)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 12,
                    color: AppColors.textTertiary(brightness),
                  ),
                ),
              // Duration
              Text(
                duration.toHumanReadable(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              MacosIconButton(
                icon: const MacosIcon(
                  CupertinoIcons.trash,
                  size: 14,
                  color: AppColors.danger,
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
