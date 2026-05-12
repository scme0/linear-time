import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../providers/report_providers.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/extensions/duration_extensions.dart';

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
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weeklySummaryProvider(_weekStart));
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    final weekLabel =
        '${dateFormat.format(_weekStart)} – ${dateFormat.format(weekEnd)}, ${weekEnd.year}';

    return Column(
      children: [
        // Week navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MacosIconButton(
                icon: const MacosIcon(CupertinoIcons.chevron_left),
                onPressed: _previousWeek,
              ),
              const SizedBox(width: 16),
              Text(
                weekLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              MacosIconButton(
                icon: const MacosIcon(CupertinoIcons.chevron_right),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),
        // Issue list
        Expanded(
          child: summary.when(
            data: (data) {
              if (data.issues.isEmpty) {
                return const Center(
                  child: Text(
                    'No time tracked this week',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.issues.length,
                itemBuilder: (context, index) {
                  final issue = data.issues[index];
                  return _IssueRow(issue: issue);
                },
              );
            },
            loading: () => const Center(child: ProgressCircle()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        // Grand total
        summary.when(
          data: (data) {
            if (data.grandTotalSeconds == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Week total: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Duration(seconds: data.grandTotalSeconds).toHumanReadable(),
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
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final IssueSummary issue;

  Color? _parseTeamColor() {
    final hex = issue.teamColor;
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final teamColor = _parseTeamColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Team color bar
          Container(
            width: 4,
            height: 28,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: teamColor ?? CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Identifier
          SizedBox(
            width: 80,
            child: Text(
              issue.identifier,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              issue.title,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Entry count
          Text(
            '${issue.entryCount} ${issue.entryCount == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(width: 16),
          // Duration
          Text(
            Duration(seconds: issue.totalSeconds).toHumanReadable(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
