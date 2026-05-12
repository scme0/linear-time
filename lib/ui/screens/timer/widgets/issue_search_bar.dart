import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/issue_providers.dart';
import '../../../widgets/searchable_dropdown.dart';
import '../timer_screen.dart';

class IssueSearchBar extends ConsumerStatefulWidget {
  const IssueSearchBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    this.onSubmitted,
    this.focusNotifier,
  });

  final IssueFilter filter;
  final ValueChanged<IssueFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onSubmitted;
  final ValueNotifier<int>? focusNotifier;

  @override
  ConsumerState<IssueSearchBar> createState() => _IssueSearchBarState();
}

class _IssueSearchBarState extends ConsumerState<IssueSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedTeamId;
  String? _selectedProjectId;
  String? _selectedStatusType;
  String? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    widget.focusNotifier?.addListener(_onFocusRequested);
  }

  @override
  void didUpdateWidget(IssueSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNotifier != widget.focusNotifier) {
      oldWidget.focusNotifier?.removeListener(_onFocusRequested);
      widget.focusNotifier?.addListener(_onFocusRequested);
    }
  }

  @override
  void dispose() {
    widget.focusNotifier?.removeListener(_onFocusRequested);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusRequested() {
    _focusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _clearSubFilters() {
    _selectedTeamId = null;
    _selectedProjectId = null;
    _selectedStatusType = null;
    _selectedAssigneeId = null;
  }

  IssueFilter get _primaryFilterValue {
    final t = widget.filter.type;
    if (t == 'recentlyTracked') return IssueFilter.recentlyTracked;
    if (t == 'allIssues') return IssueFilter.allIssues;
    return IssueFilter.myIssues;
  }

  bool get _showSubFilters => widget.filter.type != 'recentlyTracked';

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    // Derive filter options from current issue list
    final isAllIssues = widget.filter.type == 'allIssues';
    final issues = isAllIssues
        ? ref.watch(allCachedIssuesProvider).valueOrNull ?? []
        : ref.watch(assignedIssuesProvider).valueOrNull ?? [];

    final teamMap = <String, String>{};
    final projectMap = <String, String>{};
    final statusMap = <String, String>{};
    final assigneeMap = <String, String>{};
    for (final issue in issues) {
      if (issue.teamId != null && issue.teamName != null) {
        teamMap[issue.teamId!] = issue.teamName!;
      }
      if (issue.projectId != null && issue.projectName != null) {
        projectMap[issue.projectId!] = issue.projectName!;
      }
      statusMap[issue.statusType] = issue.status;
      if (issue.assigneeId != null && issue.assigneeName != null) {
        assigneeMap[issue.assigneeId!] = issue.assigneeName!;
      }
    }
    final teams = teamMap.entries
        .map((e) => (id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final projects = projectMap.entries
        .map((e) => (id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final statuses = statusMap.entries
        .map((e) => (id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final assignees = assigneeMap.entries
        .map((e) => (id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          MacosTextField(
            controller: _searchController,
            focusNode: _focusNode,
            placeholder: 'Search issues or paste ID/URL...',
            placeholderStyle: TextStyle(
              color: AppColors.textSecondary(brightness),
              fontSize: 13,
            ),
            style: TextStyle(
              color: AppColors.textPrimary(brightness),
              fontSize: 13,
            ),
            onChanged: (value) => widget.onSearchChanged(value),
            onSubmitted: (_) => widget.onSubmitted?.call(),
          ),
          const SizedBox(height: 6),
          // Filter row
          Row(
            children: [
              // Primary filter
              MacosPopupButton<IssueFilter>(
                value: _primaryFilterValue,
                items: IssueFilter.values
                    .map((f) => MacosPopupMenuItem(
                          value: f,
                          child: Text(f.label),
                        ))
                    .toList(),
                onChanged: (f) {
                  if (f != null) {
                    _clearSubFilters();
                    widget.onFilterChanged(f);
                  }
                },
              ),
              // Sub-filters
              if (_showSubFilters) ...[
                if (teams.length > 1) ...[
                  const SizedBox(width: 6),
                  SearchableDropdown<String>(
                    items: teams,
                    value: _selectedTeamId,
                    allLabel: 'All Teams',
                    labelBuilder: (id) =>
                        id != null ? teamMap[id] ?? 'Team' : 'All Teams',
                    onChanged: (v) {
                      setState(() => _selectedTeamId = v);
                      widget.onFilterChanged(IssueFilter.byTeam(v));
                    },
                  ),
                ],
                if (projects.length > 1) ...[
                  const SizedBox(width: 6),
                  SearchableDropdown<String>(
                    items: projects,
                    value: _selectedProjectId,
                    allLabel: 'All Projects',
                    labelBuilder: (id) =>
                        id != null ? projectMap[id] ?? 'Project' : 'All Projects',
                    onChanged: (v) {
                      setState(() => _selectedProjectId = v);
                      widget.onFilterChanged(IssueFilter.byProject(v));
                    },
                  ),
                ],
                if (statuses.length > 1) ...[
                  const SizedBox(width: 6),
                  SearchableDropdown<String>(
                    items: statuses,
                    value: _selectedStatusType,
                    allLabel: 'All Statuses',
                    labelBuilder: (id) =>
                        id != null ? statusMap[id] ?? 'Status' : 'All Statuses',
                    onChanged: (v) {
                      setState(() => _selectedStatusType = v);
                      widget.onFilterChanged(IssueFilter.byStatus(v));
                    },
                  ),
                ],
                if (assignees.length > 1) ...[
                  const SizedBox(width: 6),
                  SearchableDropdown<String>(
                    items: assignees,
                    value: _selectedAssigneeId,
                    allLabel: 'All Assignees',
                    labelBuilder: (id) =>
                        id != null ? assigneeMap[id] ?? 'Assignee' : 'All Assignees',
                    onChanged: (v) {
                      setState(() => _selectedAssigneeId = v);
                      widget.onFilterChanged(IssueFilter.byAssignee(v));
                    },
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
