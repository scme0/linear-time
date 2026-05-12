import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../providers/issue_providers.dart';
import '../core/theme/app_theme.dart';
import 'screens/timer/timer_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';

class AppWindow extends ConsumerStatefulWidget {
  const AppWindow({super.key});

  @override
  ConsumerState<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends ConsumerState<AppWindow> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Trigger sync on launch (no-op if not connected)
    ref.watch(syncIssuesProvider);

    final brightness = MacosTheme.of(context).brightness;

    return MacosWindow(
      child: MacosScaffold(
        toolBar: ToolBar(
          title: const Text('Linear Time'),
          titleWidth: 200,
          actions: [
            ToolBarIconButton(
              label: 'Timer',
              icon: MacosIcon(
                CupertinoIcons.timer,
                color: _pageIndex == 0
                    ? AppColors.accent
                    : AppColors.textSecondary(brightness),
              ),
              showLabel: true,
              onPressed: () => setState(() => _pageIndex = 0),
            ),
            ToolBarIconButton(
              label: 'History',
              icon: MacosIcon(
                CupertinoIcons.chart_bar_square,
                color: _pageIndex == 1
                    ? AppColors.accent
                    : AppColors.textSecondary(brightness),
              ),
              showLabel: true,
              onPressed: () => setState(() => _pageIndex = 1),
            ),
            ToolBarIconButton(
              label: 'Settings',
              icon: MacosIcon(
                CupertinoIcons.gear_alt,
                color: _pageIndex == 2
                    ? AppColors.accent
                    : AppColors.textSecondary(brightness),
              ),
              showLabel: true,
              onPressed: () => setState(() => _pageIndex = 2),
            ),
          ],
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return IndexedStack(
                index: _pageIndex,
                children: const [
                  TimerScreen(),
                  HistoryScreen(),
                  SettingsScreen(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
