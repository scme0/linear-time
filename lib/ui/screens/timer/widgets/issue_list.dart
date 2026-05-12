import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../providers/issue_providers.dart';
import '../../../../providers/repository_providers.dart';
import '../timer_screen.dart';
import 'issue_row.dart';

class IssueList extends ConsumerStatefulWidget {
  const IssueList({
    super.key,
    required this.searchQuery,
    required this.filter,
    required this.activeIssueId,
    required this.onIssueSelected,
  });

  final String searchQuery;
  final IssueFilter filter;
  final String? activeIssueId;
  final ValueChanged<CachedIssue> onIssueSelected;

  @override
  ConsumerState<IssueList> createState() => _IssueListState();
}

class _IssueListState extends ConsumerState<IssueList> {
  bool _resolving = false;
  CachedIssue? _resolvedIssue;

  @override
  void didUpdateWidget(IssueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _resolvedIssue = null;
      _tryResolveExternalIssue();
    }
  }

  /// Try to resolve pasted issue ID/URL via the API.
  Future<void> _tryResolveExternalIssue() async {
    final query = widget.searchQuery.trim();
    if (query.isEmpty) return;

    // Check if it looks like an issue ID or URL
    final isIdentifier = RegExp(r'^[A-Z]+-\d+$').hasMatch(query);
    final isUrl = query.contains('linear.app') && query.contains('/issue/');
    final isUuid = RegExp(r'^[0-9a-f-]{36}$').hasMatch(query);

    if (!isIdentifier && !isUrl && !isUuid) return;

    final repo = ref.read(issueRepositoryProvider);
    if (repo == null) return;

    setState(() => _resolving = true);
    try {
      final issue = await repo.resolveIssueQuery(query);
      if (mounted) {
        setState(() {
          _resolvedIssue = issue;
          _resolving = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.filter) {
      IssueFilter.myIssues => _buildAssignedIssues(),
      IssueFilter.recentlyTracked => _buildRecentIssues(),
    };
  }

  Widget _buildAssignedIssues() {
    final issuesAsync = ref.watch(assignedIssuesProvider);

    return issuesAsync.when(
      data: (issues) {
        var filtered = issues;

        // Apply search filter
        if (widget.searchQuery.isNotEmpty) {
          final q = widget.searchQuery.toLowerCase();
          filtered = issues
              .where((i) =>
                  i.identifier.toLowerCase().contains(q) ||
                  i.title.toLowerCase().contains(q) ||
                  (i.teamName?.toLowerCase().contains(q) ?? false) ||
                  (i.projectName?.toLowerCase().contains(q) ?? false))
              .toList();
        }

        // Add resolved external issue if not already in list
        if (_resolvedIssue != null &&
            !filtered.any((i) => i.issueId == _resolvedIssue!.issueId)) {
          filtered = [_resolvedIssue!, ...filtered];
        }

        if (filtered.isEmpty && !_resolving) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: filtered.length + (_resolving ? 1 : 0),
          itemBuilder: (context, index) {
            if (_resolving && index == 0) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    ProgressCircle(radius: 8),
                    SizedBox(width: 8),
                    Text('Looking up issue...'),
                  ],
                ),
              );
            }
            final adjustedIndex = _resolving ? index - 1 : index;
            final issue = filtered[adjustedIndex];
            return IssueRow(
              issue: issue,
              isActive: issue.issueId == widget.activeIssueId,
              onTap: () => widget.onIssueSelected(issue),
            );
          },
        );
      },
      loading: () => const Center(child: ProgressCircle()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 32),
            const SizedBox(height: 8),
            Text('Failed to load issues: $e'),
            const SizedBox(height: 12),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: () => ref.invalidate(assignedIssuesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIssues() {
    final recentAsync = ref.watch(recentTrackedIssuesProvider);

    return recentAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'No recently tracked issues',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _RecentEntryRow(
              entry: entry,
              isActive: entry.issueId == widget.activeIssueId,
              onTap: () {
                // Create a minimal CachedIssue from the time entry data
                // to start the timer
                final repo = ref.read(timeTrackingRepositoryProvider);
                repo.startTimer(
                  issueId: entry.issueId,
                  issueIdentifier: entry.issueIdentifier,
                  issueTitle: entry.issueTitle,
                  teamName: entry.teamName,
                  projectName: entry.projectName,
                  teamColor: entry.teamColor,
                );
                ref.invalidate(recentTrackedIssuesProvider);
              },
            );
          },
        );
      },
      loading: () => const Center(child: ProgressCircle()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
    final isConnected = ref.watch(issueRepositoryProvider) != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected
                ? CupertinoIcons.search
                : CupertinoIcons.link,
            size: 32,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? 'No matching issues'
                : 'Connect to Linear in Settings to see your issues',
            style: const TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _RecentEntryRow extends StatelessWidget {
  const _RecentEntryRow({
    required this.entry,
    required this.isActive,
    required this.onTap,
  });

  final TimeEntry entry;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9))
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (isActive)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: CupertinoColors.activeGreen,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              entry.issueIdentifier,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.issueTitle,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.teamName != null)
              Text(
                entry.teamName!,
                style: const TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
