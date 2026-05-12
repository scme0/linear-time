import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../providers/timer_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/active_timer_banner.dart';
import 'widgets/issue_list.dart';
import 'widgets/issue_search_bar.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  String _searchQuery = '';
  IssueFilter _filter = IssueFilter.myIssues;

  void _onIssueSelected(CachedIssue issue) {
    if (issue.isDeleted) return;
    final repo = ref.read(timeTrackingRepositoryProvider);
    repo.startTimer(
      issueId: issue.issueId,
      issueIdentifier: issue.identifier,
      issueTitle: issue.title,
      teamName: issue.teamName,
      projectName: issue.projectName,
      teamColor: issue.teamColor,
    );
    ref.invalidate(recentTrackedIssuesProvider);
  }

  void _onStopTimer() {
    final repo = ref.read(timeTrackingRepositoryProvider);
    repo.stopTimer();
    ref.invalidate(recentTrackedIssuesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeTimer = ref.watch(activeTimerProvider);
    final elapsed = ref.watch(timerTickProvider);
    final todayTotal = ref.watch(todayTotalForActiveIssueProvider);
    final brightness = MacosTheme.of(context).brightness;

    return Column(
      children: [
        // Active timer banner
        ActiveTimerBanner(
          activeTimer: activeTimer,
          elapsed: elapsed,
          todayTotal: todayTotal,
          onStop: _onStopTimer,
        ),
        Container(
          height: 1,
          color: AppColors.border(brightness),
        ),
        // Search and filter bar
        IssueSearchBar(
          filter: _filter,
          onFilterChanged: (f) => setState(() => _filter = f),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
        ),
        Container(
          height: 1,
          color: AppColors.border(brightness),
        ),
        // Issue list
        Expanded(
          child: IssueList(
            searchQuery: _searchQuery,
            filter: _filter,
            activeIssueId: activeTimer.valueOrNull?.issueId,
            onIssueSelected: _onIssueSelected,
          ),
        ),
      ],
    );
  }
}

enum IssueFilter {
  myIssues('My Issues'),
  recentlyTracked('Recently Tracked');

  const IssueFilter(this.label);
  final String label;
}
