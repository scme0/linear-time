import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../providers/report_providers.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';

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
    final brightness = MacosTheme.of(context).brightness;

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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(brightness),
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
        // Day bars with issue stripes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _WeekDayBars(weekStart: _weekStart),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.border(brightness),
        ),
        // Issue breakdown list
        Expanded(
          child: summary.when(
            data: (data) {
              if (data.issues.isEmpty) {
                return Center(
                  child: Text(
                    'No time tracked this week',
                    style: TextStyle(
                        color: AppColors.textSecondary(brightness)),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.issues.length,
                itemBuilder: (context, index) {
                  final issue = data.issues[index];
                  return _IssueRow(
                      issue: issue, brightness: brightness);
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
                  Text(
                    'Week total: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                  Text(
                    Duration(seconds: data.grandTotalSeconds).toHumanReadable(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(brightness),
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

/// Shows 7 day bars (Mon-Sun) with colored stripes per issue.
class _WeekDayBars extends ConsumerWidget {
  const _WeekDayBars({required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MacosTheme.of(context).brightness;
    final dayFormat = DateFormat('E');
    final dayNumFormat = DateFormat('d');

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final entries = ref.watch(dailyEntriesProvider(day));
          final isToday = day.isSameDay(DateTime.now());

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  // Day label
                  Text(
                    dayFormat.format(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? AppColors.accentBlue
                          : AppColors.textSecondary(brightness),
                    ),
                  ),
                  Text(
                    dayNumFormat.format(day),
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? AppColors.accentBlue
                          : AppColors.textTertiary(brightness),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stripe bar
                  Expanded(
                    child: entries.when(
                      data: (entryList) =>
                          _buildDayBar(entryList, brightness),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayBar(
      List<TimeEntry> entries, Brightness brightness) {
    if (entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.border(brightness),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Group by issue and compute seconds
    final issueSeconds = <String, int>{};
    final issueIds = <String>[];
    int totalSeconds = 0;

    for (final entry in entries) {
      if (entry.endTime == null) continue;
      final seconds = entry.durationSeconds ??
          entry.endTime!.difference(entry.startTime).inSeconds;
      totalSeconds += seconds;
      if (!issueSeconds.containsKey(entry.issueId)) {
        issueIds.add(entry.issueId);
      }
      issueSeconds[entry.issueId] =
          (issueSeconds[entry.issueId] ?? 0) + seconds;
    }

    if (totalSeconds == 0) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.border(brightness),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Column(
        children: issueIds.map((id) {
          final seconds = issueSeconds[id]!;
          final fraction = seconds / totalSeconds;
          return Flexible(
            flex: (fraction * 100).round().clamp(1, 100),
            child: Container(
              width: double.infinity,
              color: AppColors.colorForIssue(id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.brightness});

  final IssueSummary issue;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final issueColor = AppColors.colorForIssue(issue.issueId);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Issue color dot (matches bar color)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: issueColor,
              shape: BoxShape.circle,
            ),
          ),
          // Identifier
          SizedBox(
            width: 80,
            child: Text(
              issue.identifier,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary(brightness),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              issue.title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary(brightness),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Entry count
          Text(
            '${issue.entryCount} ${issue.entryCount == 1 ? 'entry' : 'entries'}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(brightness),
            ),
          ),
          const SizedBox(width: 16),
          // Duration
          Text(
            Duration(seconds: issue.totalSeconds).toHumanReadable(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(brightness),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
