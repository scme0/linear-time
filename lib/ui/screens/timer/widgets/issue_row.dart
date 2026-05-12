import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';

class IssueRow extends StatefulWidget {
  const IssueRow({
    super.key,
    required this.issue,
    required this.isActive,
    required this.onTap,
  });

  final CachedIssue issue;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<IssueRow> createState() => _IssueRowState();
}

class _IssueRowState extends State<IssueRow> {
  bool _hovering = false;

  Color? _parseTeamColor() {
    final hex = widget.issue.teamColor;
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
    final isDeleted = widget.issue.isDeleted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: isDeleted ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDeleted ? null : (widget.isActive ? null : widget.onTap),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9))
                : _hovering
                    ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
                    : null,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                width: 0.5,
              ),
            ),
          ),
          child: Opacity(
            opacity: isDeleted ? 0.5 : 1.0,
            child: Row(
              children: [
                // Team color indicator
                Container(
                  width: 4,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: teamColor ?? CupertinoColors.systemGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active indicator
                if (widget.isActive)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                // Issue identifier
                SizedBox(
                  width: 80,
                  child: Text(
                    widget.issue.identifier,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Issue title
                Expanded(
                  child: Text(
                    widget.issue.title,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: isDeleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                _StatusBadge(
                  status: widget.issue.status,
                  statusType: widget.issue.statusType,
                ),
                const SizedBox(width: 8),
                // Deleted indicator
                if (isDeleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Deleted',
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Project/Team info
                if (widget.issue.projectName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.issue.projectName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.statusType});

  final String status;
  final String statusType;

  Color get _color => switch (statusType) {
        'started' => CupertinoColors.activeBlue,
        'completed' => CupertinoColors.activeGreen,
        'cancelled' => CupertinoColors.systemGrey,
        'backlog' => CupertinoColors.systemGrey3,
        _ => CupertinoColors.systemOrange, // unstarted
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: _color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
