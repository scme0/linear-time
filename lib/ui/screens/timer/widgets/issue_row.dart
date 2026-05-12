import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/utils/open_in_linear.dart';

class IssueRow extends StatefulWidget {
  const IssueRow({
    super.key,
    required this.issue,
    required this.isActive,
    required this.onTap,
    this.onAddTime,
    this.todaySeconds = 0,
    this.isKeyboardSelected = false,
  });

  final CachedIssue issue;
  final bool isActive;
  final bool isKeyboardSelected;
  final VoidCallback onTap;
  final VoidCallback? onAddTime;
  final int todaySeconds;

  @override
  State<IssueRow> createState() => _IssueRowState();
}

class _IssueRowState extends State<IssueRow> {
  bool _hovering = false;


  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDeleted = widget.issue.isDeleted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: isDeleted
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDeleted ? null : (widget.isActive ? null : widget.onTap),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.activeTimerBg(brightness)
                : (_hovering || widget.isKeyboardSelected)
                    ? AppColors.hover(brightness)
                    : null,
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                    width: 1,
                  )
                : widget.isKeyboardSelected
                    ? Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
          ),
          child: Opacity(
            opacity: isDeleted ? 0.5 : 1.0,
            child: Row(
              children: [
                // Issue color indicator (consistent across all views)
                Container(
                  width: 4,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.colorForIssue(widget.issue.issueId),
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
                      color: AppColors.success,
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
                      color: AppColors.textPrimary(brightness),
                      decoration:
                          isDeleted ? TextDecoration.lineThrough : null,
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
                      color: AppColors.textPrimary(brightness),
                      decoration:
                          isDeleted ? TextDecoration.lineThrough : null,
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
                  brightness: brightness,
                ),
                // Deleted indicator
                if (isDeleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Deleted',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                // Today's tracked time
                if (widget.todaySeconds > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      Duration(seconds: widget.todaySeconds).toHumanReadable(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                  ),
                // Project name
                if (widget.issue.projectName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.issue.projectName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(brightness),
                    ),
                  ),
                ],
                // Add time button
                if (widget.onAddTime != null && !isDeleted && _hovering)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: MacosIconButton(
                      icon: MacosIcon(
                        CupertinoIcons.plus_circle,
                        size: 16,
                        color: AppColors.textTertiary(brightness),
                      ),
                      onPressed: widget.onAddTime,
                    ),
                  ),
                // Open in Linear
                if (!isDeleted && _hovering)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: MacosIconButton(
                      icon: MacosIcon(
                        CupertinoIcons.arrow_up_right_square,
                        size: 14,
                        color: AppColors.textTertiary(brightness),
                      ),
                      onPressed: () => openInLinear(
                        url: widget.issue.url,
                        identifier: widget.issue.identifier,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.statusType,
    required this.brightness,
  });

  final String status;
  final String statusType;
  final Brightness brightness;

  Color get _color => switch (statusType) {
        'started' => AppColors.statusStarted,
        'completed' => AppColors.statusCompleted,
        'cancelled' => AppColors.statusCancelled,
        'backlog' => AppColors.statusBacklog,
        _ => AppColors.statusUnstarted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
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
