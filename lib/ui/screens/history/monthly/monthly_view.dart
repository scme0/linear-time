import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../providers/report_providers.dart';
import '../../../../providers/settings_providers.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import 'widgets/day_cell.dart';

class MonthlyView extends ConsumerStatefulWidget {
  const MonthlyView({super.key, required this.onDaySelected});

  final ValueChanged<DateTime> onDaySelected;

  @override
  ConsumerState<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<MonthlyView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final calendarData = ref.watch(monthlyCalendarDataProvider(_currentMonth));
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const AppSettings();
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);
    final totalSeconds = calendarData.valueOrNull?.values
            .fold<int>(0, (sum, d) => sum + d.totalSeconds) ??
        0;
    final workDaySeconds =
        (settings.officeEndHour - settings.officeStartHour) * 3600;

    return Column(
      children: [
        // Month navigator
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
                    onPressed: _previousMonth,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              if (!_isCurrentMonth)
                Positioned(
                  left: 0,
                  child: PushButton(
                    controlSize: ControlSize.small,
                    secondary: true,
                    onPressed: () {
                      final now = DateTime.now();
                      setState(
                          () => _currentMonth = DateTime(now.year, now.month));
                    },
                    child: const Text('This Month'),
                  ),
                ),
            ],
          ),
        ),
        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        Expanded(
          child: calendarData.when(
            data: (dayMap) =>
                _buildCalendarGrid(dayMap, workDaySeconds),
            loading: () => const Center(child: ProgressCircle()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        // Legend
        calendarData.when(
          data: (dayMap) =>
              _buildLegend(dayMap, totalSeconds, brightness),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLegend(
      Map<int, DayData> dayMap, int totalSeconds, Brightness brightness) {
    if (totalSeconds == 0) return const SizedBox.shrink();

    // Aggregate issues across all days
    final issueSeconds = <String, int>{};
    final issueLabels = <String, String>{};
    for (final day in dayMap.values) {
      for (final entry in day.issueSeconds.entries) {
        issueSeconds[entry.key] =
            (issueSeconds[entry.key] ?? 0) + entry.value;
        if (day.issueLabels.containsKey(entry.key)) {
          issueLabels[entry.key] = day.issueLabels[entry.key]!;
        }
      }
    }

    final sorted = issueSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border(brightness), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          ...sorted.map((entry) {
            final label = issueLabels[entry.key] ?? entry.key;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.colorForIssue(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$label ${Duration(seconds: entry.value).toHumanReadable()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
              ],
            );
          }),
          // Total
          Text(
            'Total: ${Duration(seconds: totalSeconds).toHumanReadable()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Map<int, DayData> dayMap, int workDaySeconds) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Expanded(
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }
                final data = dayMap[dayNum];
                final date = DateTime(
                    _currentMonth.year, _currentMonth.month, dayNum);
                final isToday = _isToday(date);
                return Expanded(
                  child: DayCell(
                    day: dayNum,
                    data: data,
                    isToday: isToday,
                    onTap: () => widget.onDaySelected(date),
                    workDaySeconds: workDaySeconds,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
