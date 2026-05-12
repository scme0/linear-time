import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'monthly/monthly_view.dart';
import 'weekly/weekly_view.dart';
import 'daily/daily_view.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _tabIndex = 0;
  DateTime? _selectedDay;
  late MacosTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = MacosTabController(initialIndex: 0, length: 3);
    _tabController.addListener(() {
      if (_tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _tabIndex = 2;
      _tabController.index = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MacosSegmentedControl(
            controller: _tabController,
            tabs: const [
              MacosTab(label: 'Monthly'),
              MacosTab(label: 'Weekly'),
              MacosTab(label: 'Daily'),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              MonthlyView(onDaySelected: _navigateToDay),
              const WeeklyView(),
              DailyView(initialDate: _selectedDay),
            ],
          ),
        ),
      ],
    );
  }
}
