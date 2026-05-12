import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:macos_ui/macos_ui.dart';

import '../../../../../providers/report_providers.dart';
import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/time_format.dart';
import '../../../../../core/theme/app_theme.dart';

class DayCell extends StatefulWidget {
  const DayCell({
    super.key,
    required this.day,
    this.data,
    required this.isToday,
    required this.onTap,
    this.workDaySeconds = 8 * 3600,
  });

  final int day;
  final DayData? data;
  final bool isToday;
  final VoidCallback onTap;
  final int workDaySeconds;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final hasData = widget.data != null && widget.data!.totalSeconds > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: hasData ? _buildTooltipText() : '',
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: _hovering
                  ? AppColors.hover(brightness)
                  : (hasData ? AppColors.selected(brightness) : null),
              borderRadius: BorderRadius.circular(6),
              border: widget.isToday
                  ? Border.all(color: AppColors.accent, width: 1.5)
                  : Border.all(
                      color: AppColors.border(brightness), width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: widget.isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: widget.isToday ? AppColors.accent : null,
                        ),
                      ),
                      if (hasData)
                        Text(
                          Duration(seconds: widget.data!.totalSeconds)
                              .formatted(TimeFormat.current),
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (hasData) Expanded(child: _buildStripes()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildTooltipText() {
    final data = widget.data!;
    final entries = data.issueSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final lines = entries.map((e) {
      final label = data.issueLabels[e.key] ?? e.key;
      final dur = Duration(seconds: e.value).formatted(TimeFormat.current);
      return '$label: $dur';
    });
    return lines.join('\n');
  }

  Widget _buildStripes() {
    final data = widget.data!;
    final brightness = MacosTheme.of(context).brightness;
    final entries = data.issueSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Proportion of work day that was tracked
    final trackedFraction =
        (data.totalSeconds / widget.workDaySeconds).clamp(0.0, 1.0);
    final emptyFraction = 1.0 - trackedFraction;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Row(
        children: [
          // Issue color segments proportional to tracked time
          ...entries.map((entry) {
            final fraction = entry.value / widget.workDaySeconds;
            return Flexible(
              flex: (fraction * 1000).round().clamp(1, 1000),
              child: Container(
                color: AppColors.colorForIssue(entry.key),
              ),
            );
          }),
          // Empty space for untracked portion
          if (emptyFraction > 0.01)
            Flexible(
              flex: (emptyFraction * 1000).round().clamp(1, 1000),
              child: Container(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}
