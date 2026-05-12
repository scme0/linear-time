import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../data/database/app_database.dart';
import '../../../../core/extensions/duration_extensions.dart';

class ActiveTimerBanner extends StatelessWidget {
  const ActiveTimerBanner({
    super.key,
    required this.activeTimer,
    required this.elapsed,
    required this.todayTotal,
    required this.onStop,
  });

  final AsyncValue<TimeEntry?> activeTimer;
  final AsyncValue<Duration> elapsed;
  final AsyncValue<int> todayTotal;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return activeTimer.when(
      data: (entry) {
        if (entry == null) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            color: isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF5F5F5),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 36,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No active timer',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Select an issue below to start tracking',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.tertiaryLabel,
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
            color: isDark
                ? const Color(0xFF1A2E1A)
                : const Color(0xFFE8F5E9),
            border: const Border(
              bottom: BorderSide(
                color: CupertinoColors.activeGreen,
                width: 2,
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
                  color: CupertinoColors.activeGreen,
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
                        Text(
                          entry.issueIdentifier,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (entry.teamName != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            entry.teamName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.issueTitle,
                      style: const TextStyle(fontSize: 13),
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
                  elapsed.when(
                    data: (d) => Text(
                      d.toHms(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    loading: () => const Text(
                      '00:00:00',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                    ),
                    error: (_, _) => const Text('--:--:--'),
                  ),
                  todayTotal.when(
                    data: (seconds) {
                      if (seconds == 0) return const SizedBox.shrink();
                      return Text(
                        'Today: ${Duration(seconds: seconds).toHumanReadable()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Stop button
              PushButton(
                controlSize: ControlSize.large,
                color: CupertinoColors.destructiveRed,
                onPressed: onStop,
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
