import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../providers/timer_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/report_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/duration_extensions.dart';
import '../../../core/time_format.dart';
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
    this.filterModeNotifier,
  });

  final ValueNotifier<int>? searchFocusNotifier;
  final ValueNotifier<String?>? hotkeyFilterNotifier;
  final ValueNotifier<IssueFilterMode?>? filterModeNotifier;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  String _searchQuery = '';
  IssueFilterMode _mode = IssueFilterMode.myIssues;
  SubFilters _subFilters = const SubFilters();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.hotkeyFilterNotifier?.addListener(_onHotkeyFilter);
    widget.filterModeNotifier?.addListener(_onFilterModeChanged);
  }

  @override
  void dispose() {
    widget.hotkeyFilterNotifier?.removeListener(_onHotkeyFilter);
    widget.filterModeNotifier?.removeListener(_onFilterModeChanged);
    super.dispose();
  }

  void _onFilterModeChanged() {
    final mode = widget.filterModeNotifier?.value;
    if (mode != null) {
      setState(() {
        _mode = mode;
        _subFilters = const SubFilters();
        _selectedIndex = 0;
      });
    }
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
    // Unfocus search bar so keyboard shortcuts work again
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSearchSubmitted() {
    // The IssueList filters and renders the list — we need the same
    // filtered list here. Use the same logic to get it.
    final isAllIssues = _mode == IssueFilterMode.allIssues;
    var issues = isAllIssues
        ? ref.read(allCachedIssuesProvider).valueOrNull ?? []
        : ref.read(assignedIssuesProvider).valueOrNull ?? [];

    // Apply sub-filters
    if (_subFilters.teamId != null) {
      issues = issues.where((i) => i.teamId == _subFilters.teamId).toList();
    }
    if (_subFilters.projectId != null) {
      issues = issues.where((i) => i.projectId == _subFilters.projectId).toList();
    }
    if (_subFilters.statusType != null) {
      issues = issues.where((i) => i.statusType == _subFilters.statusType).toList();
    }
    if (_subFilters.assigneeId != null) {
      issues = issues.where((i) => i.assigneeId == _subFilters.assigneeId).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      issues = issues.where((i) =>
          i.identifier.toLowerCase().contains(q) ||
          i.title.toLowerCase().contains(q) ||
          (i.teamName?.toLowerCase().contains(q) ?? false) ||
          (i.projectName?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Select at index
    final idx = _selectedIndex.clamp(0, issues.length - 1);
    if (issues.isNotEmpty) {
      _onIssueSelected(issues[idx]);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEntries = ref.watch(dailyEntriesProvider(today));
    final brightness = MacosTheme.of(context).brightness;

    return Column(
      children: [
        ActiveTimerBanner(
          activeTimer: activeTimer,
          elapsed: elapsed,
          onStop: _onStopTimer,
        ),
        Container(
          height: 1,
          color: AppColors.border(brightness),
        ),
        _TodayTotalStrip(
          todayEntries: todayEntries,
          brightness: brightness,
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
          onSearchChanged: (q) => setState(() {
            _searchQuery = q;
            _selectedIndex = 0; // Reset selection on search change
          }),
          onSubmitted: _onSearchSubmitted,
          onArrowDown: () => setState(() => _selectedIndex++),
          onArrowUp: () => setState(() {
            if (_selectedIndex > 0) _selectedIndex--;
          }),
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
            selectedIndex: _selectedIndex,
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

class _TodayTotalStrip extends StatelessWidget {
  const _TodayTotalStrip({
    required this.todayEntries,
    required this.brightness,
  });

  final AsyncValue<List<TimeEntry>> todayEntries;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final entries = todayEntries.valueOrNull;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold<int>(0, (sum, e) =>
        sum + (e.durationSeconds ??
            (e.endTime ?? DateTime.now()).difference(e.startTime).inSeconds));

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface(brightness),
      child: Row(
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(brightness),
            ),
          ),
          const Spacer(),
          Text(
            Duration(seconds: total).formatted(TimeFormat.current),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
