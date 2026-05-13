import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../core/utils/open_in_linear.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveTimerBanner extends StatefulWidget {
  const ActiveTimerBanner({
    super.key,
    required this.activeTimer,
    required this.elapsed,
    required this.onStop,
  });

  final AsyncValue<TimeEntry?> activeTimer;
  final AsyncValue<Duration> elapsed;
  final VoidCallback onStop;

  @override
  State<ActiveTimerBanner> createState() => _ActiveTimerBannerState();
}

class _ActiveTimerBannerState extends State<ActiveTimerBanner> {
  bool _identifierHovering = false;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return widget.activeTimer.when(
      data: (entry) {
        if (entry == null) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            color: AppColors.surface(brightness),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 36,
                    color: AppColors.textTertiary(brightness),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active timer',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary(brightness),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select an issue below to start tracking',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary(brightness),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.activeTimerBg(brightness),
            border: Border(
              bottom: BorderSide(
                color: AppColors.success.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Pulsing green dot
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Issue info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _identifierHovering = true),
                          onExit: (_) => setState(() => _identifierHovering = false),
                          child: GestureDetector(
                            onTap: () => openInLinear(
                              identifier: entry.issueIdentifier,
                            ),
                            child: Text(
                              entry.issueIdentifier,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _identifierHovering
                                    ? AppColors.accent
                                    : AppColors.textPrimary(brightness),
                                decoration: _identifierHovering
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        if (entry.teamName != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            entry.teamName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(brightness),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.issueTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary(brightness),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Timer display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  widget.elapsed.when(
                    data: (d) => Text(
                      d.toHms(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary(brightness),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    loading: () => Text(
                      '00:00:00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary(brightness),
                      ),
                    ),
                    error: (_, _) => const Text('--:--:--'),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Stop button
              PushButton(
                controlSize: ControlSize.large,
                color: AppColors.danger,
                onPressed: widget.onStop,
                child: const Text('Stop'),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: ProgressCircle()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $e'),
      ),
    );
  }
}
