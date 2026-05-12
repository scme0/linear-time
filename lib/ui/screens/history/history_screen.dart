import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'monthly/monthly_view.dart';
import 'weekly/weekly_view.dart';
import 'daily/daily_view.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _tabIndex = 0;
  DateTime? _selectedDay;

  void _navigateToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _tabIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return Column(
      children: [
        // Custom segmented control
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surface2(brightness),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentButton(
                  label: 'Monthly',
                  isActive: _tabIndex == 0,
                  brightness: brightness,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _SegmentButton(
                  label: 'Weekly',
                  isActive: _tabIndex == 1,
                  brightness: brightness,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                _SegmentButton(
                  label: 'Daily',
                  isActive: _tabIndex == 2,
                  brightness: brightness,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              MonthlyView(onDaySelected: _navigateToDay),
              const WeeklyView(),
              DailyView(initialDate: _selectedDay),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatefulWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.brightness,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.surface(widget.brightness)
                : _hovering
                    ? AppColors.hover(widget.brightness)
                    : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive
                  ? AppColors.textPrimary(widget.brightness)
                  : AppColors.textSecondary(widget.brightness),
            ),
          ),
        ),
      ),
    );
  }
}
