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
import '../../tray/tray_manager.dart';
import '../../../services/notification_service.dart';
import 'widgets/active_timer_banner.dart';
import 'widgets/issue_list.dart';
import 'widgets/issue_search_bar.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({
    super.key,
    this.searchFocusNotifier,
    this.hotkeyFilterNotifier,
  });

  final ValueNotifier<int>? searchFocusNotifier;
  final ValueNotifier<String?>? hotkeyFilterNotifier;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  String _searchQuery = '';
  IssueFilterMode _mode = IssueFilterMode.myIssues;
  SubFilters _subFilters = const SubFilters();

  @override
  void initState() {
    super.initState();
    widget.hotkeyFilterNotifier?.addListener(_onHotkeyFilter);
  }

  @override
  void dispose() {
    widget.hotkeyFilterNotifier?.removeListener(_onHotkeyFilter);
    super.dispose();
  }

  void _onHotkeyFilter() {
    final val = widget.hotkeyFilterNotifier?.value;
    setState(() {
      _mode = val == 'allIssues'
          ? IssueFilterMode.allIssues
          : IssueFilterMode.myIssues;
      _subFilters = const SubFilters();
    });
  }

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
    _refreshTray();
  }

  void _refreshTray() {
    // Small delay to let provider state settle after start/stop
    Future.delayed(const Duration(milliseconds: 200), () {
      TrayManager.instance?.updateMenu();
      TrayManager.instance?.updateTitle();
    });
    NotificationService.instance?.onTimerStateChanged();
  }

  void _onSearchSubmitted() {
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
    _refreshTray();
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
        IssueSearchBar(
          mode: _mode,
          subFilters: _subFilters,
          onModeChanged: (m) => setState(() {
            _mode = m;
            _subFilters = const SubFilters();
          }),
          onSubFiltersChanged: (f) => setState(() => _subFilters = f),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onSubmitted: _onSearchSubmitted,
          focusNotifier: widget.searchFocusNotifier,
        ),
        Container(
          height: 1,
          color: AppColors.border(brightness),
        ),
        Expanded(
          child: IssueList(
            searchQuery: _searchQuery,
            mode: _mode,
            subFilters: _subFilters,
            activeIssueId: activeTimer.valueOrNull?.issueId,
            onIssueSelected: _onIssueSelected,
            onAddTime: _onAddTime,
          ),
        ),
      ],
    );
  }
}

enum IssueFilterMode {
  myIssues('My Issues'),
  allIssues('All Issues'),
  recentlyTracked('Recently Tracked');

  const IssueFilterMode(this.label);
  final String label;
}

class SubFilters {
  final String? teamId;
  final String? projectId;
  final String? statusType;
  final String? assigneeId;

  const SubFilters({
    this.teamId,
    this.projectId,
    this.statusType,
    this.assigneeId,
  });

  SubFilters copyWith({
    String? Function()? teamId,
    String? Function()? projectId,
    String? Function()? statusType,
    String? Function()? assigneeId,
  }) {
    return SubFilters(
      teamId: teamId != null ? teamId() : this.teamId,
      projectId: projectId != null ? projectId() : this.projectId,
      statusType: statusType != null ? statusType() : this.statusType,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
    );
  }

  bool get isEmpty =>
      teamId == null &&
      projectId == null &&
      statusType == null &&
      assigneeId == null;
}
