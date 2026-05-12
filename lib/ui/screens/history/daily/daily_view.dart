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
    _selectedDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
  }

  @override
  void didUpdateWidget(DailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null && widget.initialDate != oldWidget.initialDate) {
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
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _deleteEntry(int id) async {
    final dao = ref.read(timeEntryDaoProvider);
    await dao.deleteEntry(id);
    ref.invalidate(dailyEntriesProvider(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final entries = ref.watch(dailyEntriesProvider(_selectedDate));
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    final isToday = _isToday(_selectedDate);

    return Column(
      children: [
        // Date navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
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
                  if (isToday)
                    Text(
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
        ),
        // Entry list
        Expanded(
          child: entries.when(
            data: (entryList) {
              if (entryList.isEmpty) {
                return Center(
                  child: Text(
                    'No time tracked on this day',
                    style: TextStyle(color: AppColors.textSecondary(brightness)),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entryList.length,
                itemBuilder: (context, index) {
                  final entry = entryList[index];
                  return _EntryCard(
                    entry: entry,
                    onDelete: () => _deleteEntry(entry.id),
                  );
                },
              );
            },
            loading: () => const Center(child: ProgressCircle()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        // Day total
        entries.when(
          data: (entryList) {
            final totalSeconds = entryList
                .where((e) => e.endTime != null)
                .fold<int>(
                    0,
                    (sum, e) =>
                        sum +
                        (e.durationSeconds ??
                            e.endTime!.difference(e.startTime).inSeconds));
            if (totalSeconds == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Day total: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Duration(seconds: totalSeconds).toHumanReadable(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onDelete});

  final TimeEntry entry;
  final VoidCallback onDelete;

  Color? _parseTeamColor() {
    final hex = entry.teamColor;
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final teamColor = _parseTeamColor();
    final timeFormat = DateFormat('HH:mm');
    final isRunning = entry.endTime == null;
    final duration = isRunning
        ? DateTime.now().difference(entry.startTime)
        : Duration(
            seconds: entry.durationSeconds ??
                entry.endTime!.difference(entry.startTime).inSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: teamColor ?? AppColors.textTertiary(brightness),
            width: 3,
          ),
          bottom: BorderSide(
            color: AppColors.border(brightness),
            width: 0.5,
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
                  ? '${timeFormat.format(entry.startTime)} – now'
                  : '${timeFormat.format(entry.startTime)} – ${timeFormat.format(entry.endTime!)}',
              style: TextStyle(
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textSecondary(brightness),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Issue identifier
          Text(
            entry.issueIdentifier,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          // Issue title
          Expanded(
            child: Text(
              entry.issueTitle,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Manual badge
          if (entry.isManual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
