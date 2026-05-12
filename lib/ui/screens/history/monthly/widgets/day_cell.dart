import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../providers/report_providers.dart';
import '../../../../../core/extensions/duration_extensions.dart';

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

  Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return CupertinoColors.systemGrey;
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
                ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
                : (hasData
                    ? (isDark
                        ? const Color(0xFF1A2A1A)
                        : const Color(0xFFF0F8F0))
                    : null),
            borderRadius: BorderRadius.circular(6),
            border: widget.isToday
                ? Border.all(
                    color: CupertinoColors.activeBlue,
                    width: 1.5,
                  )
                : Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE0E0E0),
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
                            ? CupertinoColors.activeBlue
                            : null,
                      ),
                    ),
                    if (hasData)
                      Text(
                        Duration(seconds: widget.data!.totalSeconds)
                            .toHumanReadable(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Color stripes per project
                if (hasData) _buildStripes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStripes() {
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
                colorHex != null ? _parseHex(colorHex) : CupertinoColors.systemGrey;
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
