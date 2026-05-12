import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../providers/timer_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/report_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../history/daily/widgets/time_entry_dialog.dart';
import 'widgets/active_timer_banner.dart';
import 'widgets/issue_list.dart';
import 'widgets/issue_search_bar.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.searchFocusNotifier});

  final ValueNotifier<int>? searchFocusNotifier;

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

  void _onSearchSubmitted() {
    // Select the first visible issue in the filtered list
    final issues = ref.read(assignedIssuesProvider).valueOrNull ?? [];
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final filtered = issues.where((i) =>
          i.identifier.toLowerCase().contains(q) ||
          i.title.toLowerCase().contains(q) ||
          (i.teamName?.toLowerCase().contains(q) ?? false) ||
          (i.projectName?.toLowerCase().contains(q) ?? false));
      if (filtered.isNotEmpty) {
        _onIssueSelected(filtered.first);
      }
    } else if (issues.isNotEmpty) {
      _onIssueSelected(issues.first);
    }
  }

  void _onStopTimer() {
    final repo = ref.read(timeTrackingRepositoryProvider);
    repo.stopTimer();
    ref.invalidate(recentTrackedIssuesProvider);
  }

  Future<void> _onAddTime(CachedIssue issue) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (context) => TimeEntryDialog(
        date: today,
        preselectedIssue: issue,
      ),
    );
    if (result == true) {
      ref.invalidate(dailyEntriesProvider(today));
    }
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
          onSubmitted: _onSearchSubmitted,
          focusNotifier: widget.searchFocusNotifier,
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
            onAddTime: _onAddTime,
          ),
        ),
      ],
    );
  }
}

class IssueFilter {
  final String label;
  final String type; // 'myIssues', 'recentlyTracked', 'byTeam', 'byProject', 'byStatus'
  final String? filterId;

  const IssueFilter._(this.label, this.type, [this.filterId]);

  static const myIssues = IssueFilter._('My Issues', 'myIssues');
  static const recentlyTracked = IssueFilter._('Recently Tracked', 'recentlyTracked');
  static IssueFilter byTeam(String? teamId) =>
      IssueFilter._(teamId != null ? 'Team' : 'My Issues', teamId != null ? 'byTeam' : 'myIssues', teamId);
  static IssueFilter byProject(String? projectId) =>
      IssueFilter._(projectId != null ? 'Project' : 'My Issues', projectId != null ? 'byProject' : 'myIssues', projectId);
  static IssueFilter byStatus(String? statusType) =>
      IssueFilter._(statusType != null ? 'Status' : 'My Issues', statusType != null ? 'byStatus' : 'myIssues', statusType);

  static const values = [myIssues, recentlyTracked];

  @override
  bool operator ==(Object other) =>
      other is IssueFilter && other.type == type && other.filterId == filterId;
  @override
  int get hashCode => Object.hash(type, filterId);
}
