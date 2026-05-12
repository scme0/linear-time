import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../providers/report_providers.dart';
import '../../../../core/extensions/duration_extensions.dart';
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

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(monthlyCalendarDataProvider(_currentMonth));
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);

    return Column(
      children: [
        // Month navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
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
            data: (dayMap) => _buildCalendarGrid(dayMap),
            loading: () => const Center(child: ProgressCircle()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        // Month total
        calendarData.when(
          data: (dayMap) {
            final totalSeconds =
                dayMap.values.fold<int>(0, (sum, d) => sum + d.totalSeconds);
            if (totalSeconds == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Month total: ${Duration(seconds: totalSeconds).toHumanReadable()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<int, DayData> dayMap) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Monday = 1, so offset is (weekday - 1)
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
