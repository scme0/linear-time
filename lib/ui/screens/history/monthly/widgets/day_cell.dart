import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../providers/report_providers.dart';
import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/theme/app_theme.dart';

class DayCell extends StatefulWidget {
  const DayCell({
    super.key,
    required this.day,
    this.data,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final DayData? data;
  final bool isToday;
  final VoidCallback onTap;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  bool _hovering = false;

  Color _parseHex(String hex, Brightness brightness) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return AppColors.textTertiary(brightness);
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final hasData = widget.data != null && widget.data!.totalSeconds > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.hover(brightness)
                : (hasData
                    ? (isDark
                        ? const Color(0xFF1A2A1A)
                        : const Color(0xFFF0F8F0))
                    : null),
            borderRadius: BorderRadius.circular(6),
            border: widget.isToday
                ? Border.all(
                    color: AppColors.accent,
                    width: 1.5,
                  )
                : Border.all(
                    color: AppColors.border(brightness),
                    width: 0.5,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number and total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            widget.isToday ? FontWeight.bold : FontWeight.w500,
                        color: widget.isToday
                            ? AppColors.accent
                            : null,
                      ),
                    ),
                    if (hasData)
                      Text(
                        Duration(seconds: widget.data!.totalSeconds)
                            .toHumanReadable(),
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Color stripes per project
                if (hasData) _buildStripes(brightness),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStripes(Brightness brightness) {
    final data = widget.data!;
    final entries = data.projectSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 6,
        child: Row(
          children: entries.map((entry) {
            final fraction = entry.value / data.totalSeconds;
            final colorHex = data.projectColors[entry.key];
            final color =
                colorHex != null ? _parseHex(colorHex, brightness) : AppColors.textTertiary(brightness);
            return Flexible(
              flex: (fraction * 100).round().clamp(1, 100),
              child: Container(color: color),
            );
          }).toList(),
        ),
      ),
    );
  }
}
