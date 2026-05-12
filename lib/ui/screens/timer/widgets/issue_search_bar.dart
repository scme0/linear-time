import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/issue_providers.dart';
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
  }

  IssueFilter get _primaryFilterValue {
    final t = widget.filter.type;
    if (t == 'recentlyTracked') return IssueFilter.recentlyTracked;
    if (t == 'allIssues') return IssueFilter.allIssues;
    return IssueFilter.myIssues;
  }

  bool get _showSubFilters =>
      widget.filter.type != 'recentlyTracked';

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    // Derive all filter options from the current issue list
    final isAllIssues = widget.filter.type == 'allIssues';
    final issues = isAllIssues
        ? ref.watch(allCachedIssuesProvider).valueOrNull ?? []
        : ref.watch(assignedIssuesProvider).valueOrNull ?? [];

    final teamMap = <String, String>{};
    final projectMap = <String, String>{};
    final statusMap = <String, String>{};
    for (final issue in issues) {
      if (issue.teamId != null && issue.teamName != null) {
        teamMap[issue.teamId!] = issue.teamName!;
      }
      if (issue.projectId != null && issue.projectName != null) {
        projectMap[issue.projectId!] = issue.projectName!;
      }
      statusMap[issue.statusType] = issue.status;
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
        .map((e) => (type: e.key, name: e.value))
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
                  const SizedBox(width: 8),
                  MacosPopupButton<String?>(
                    value: _selectedTeamId,
                    items: [
                      const MacosPopupMenuItem(
                        value: null,
                        child: Text('All Teams'),
                      ),
                      ...teams.map((t) => MacosPopupMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedTeamId = v);
                      widget.onFilterChanged(IssueFilter.byTeam(v));
                    },
                  ),
                ],
                if (projects.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  MacosPopupButton<String?>(
                    value: _selectedProjectId,
                    items: [
                      const MacosPopupMenuItem(
                        value: null,
                        child: Text('All Projects'),
                      ),
                      ...projects.map((p) => MacosPopupMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedProjectId = v);
                      widget.onFilterChanged(IssueFilter.byProject(v));
                    },
                  ),
                ],
                if (statuses.length > 1) ...[
                  const SizedBox(width: 8),
                  MacosPopupButton<String?>(
                    value: _selectedStatusType,
                    items: [
                      const MacosPopupMenuItem(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...statuses.map((s) => MacosPopupMenuItem(
                            value: s.type,
                            child: Text(s.name),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedStatusType = v);
                      widget.onFilterChanged(IssueFilter.byStatus(v));
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
