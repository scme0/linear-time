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
      titleBar: TitleBar(
        height: 52,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabButton(
              icon: CupertinoIcons.timer,
              label: 'Timer',
              isActive: _pageIndex == 0,
              brightness: brightness,
              onTap: () => setState(() => _pageIndex = 0),
            ),
            const SizedBox(width: 4),
            _TabButton(
              icon: CupertinoIcons.chart_bar_square,
              label: 'History',
              isActive: _pageIndex == 1,
              brightness: brightness,
              onTap: () => setState(() => _pageIndex = 1),
            ),
            const SizedBox(width: 4),
            _TabButton(
              icon: CupertinoIcons.gear_alt,
              label: 'Settings',
              isActive: _pageIndex == 2,
              brightness: brightness,
              onTap: () => setState(() => _pageIndex = 2),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _pageIndex,
              children: const [
                TimerScreen(),
                HistoryScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.brightness,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppColors.accent
        : _hovering
            ? AppColors.textPrimary(widget.brightness)
            : AppColors.textSecondary(widget.brightness);

    final bgColor = widget.isActive
        ? AppColors.accent.withValues(alpha: 0.1)
        : _hovering
            ? AppColors.hover(widget.brightness)
            : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
