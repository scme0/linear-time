import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

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
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: _pageIndex,
            onChanged: (index) => setState(() => _pageIndex = index),
            items: const [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.timer),
                label: Text('Timer'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.chart_bar),
                label: Text('History'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.settings),
                label: Text('Settings'),
              ),
            ],
          );
        },
        bottom: const MacosListTile(
          leading: MacosIcon(CupertinoIcons.clock),
          title: Text(
            'Linear Time',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('v0.1.0'),
        ),
      ),
      child: IndexedStack(
        index: _pageIndex,
        children: const [
          TimerScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
