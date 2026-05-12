import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../providers/timer_providers.dart';
import '../../../core/extensions/duration_extensions.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTimer = ref.watch(activeTimerProvider);
    final elapsed = ref.watch(timerTickProvider);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Timer'),
        titleWidth: 150,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  activeTimer.when(
                    data: (entry) {
                      if (entry == null) {
                        return const Text(
                          'No active timer',
                          style: TextStyle(fontSize: 24),
                        );
                      }
                      return Column(
                        children: [
                          Text(
                            entry.issueIdentifier,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.issueTitle,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          elapsed.when(
                            data: (d) => Text(
                              d.toHms(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            loading: () => const Text('00:00:00',
                                style: TextStyle(fontSize: 48)),
                            error: (_, __) => const Text('--:--:--'),
                          ),
                        ],
                      );
                    },
                    loading: () => const ProgressCircle(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Select an issue below to start tracking',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                  // TODO: Issue picker widget
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
