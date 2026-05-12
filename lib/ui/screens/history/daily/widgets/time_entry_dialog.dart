import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../data/database/app_database.dart';
import '../../../../../providers/database_providers.dart';
import '../../../../../providers/issue_providers.dart';
import '../../../../../core/theme/app_theme.dart';

/// Dialog for creating or editing a time entry.
class TimeEntryDialog extends ConsumerStatefulWidget {
  const TimeEntryDialog({
    super.key,
    required this.date,
    this.existingEntry,
    this.preselectedIssue,
    this.prefilledStartHour,
  });

  final DateTime date;
  final TimeEntry? existingEntry;
  final CachedIssue? preselectedIssue;
  final int? prefilledStartHour;

  bool get isEditing => existingEntry != null;

  @override
  ConsumerState<TimeEntryDialog> createState() => _TimeEntryDialogState();
}

class _TimeEntryDialogState extends ConsumerState<TimeEntryDialog> {
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;
  CachedIssue? _selectedIssue;
  String? _error;

  /// Round minute to nearest 5-min increment (for popup compatibility).
  static int _roundToFive(int minute) => (minute / 5).round() * 5 % 60;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final e = widget.existingEntry!;
      _startHour = e.startTime.hour;
      _startMinute = _roundToFive(e.startTime.minute);
      _endHour = e.endTime?.hour ?? DateTime.now().hour;
      _endMinute = _roundToFive(e.endTime?.minute ?? DateTime.now().minute);
    } else {
      final now = DateTime.now();
      _startHour = widget.prefilledStartHour ?? now.hour;
      _startMinute = 0;
      _endHour = widget.prefilledStartHour != null
          ? widget.prefilledStartHour! + 1
          : now.hour;
      _endMinute = widget.prefilledStartHour != null
          ? 0
          : _roundToFive(now.minute);
    }
    _selectedIssue = widget.preselectedIssue;
  }

  DateTime get _startTime => DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _startHour,
        _startMinute,
      );

  DateTime get _endTime => DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _endHour,
        _endMinute,
      );

  Future<void> _save() async {
    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }

    final dao = ref.read(timeEntryDaoProvider);

    if (widget.isEditing) {
      final entry = widget.existingEntry!;
      final duration = _endTime.difference(_startTime).inSeconds;
      await dao.updateEntry(
        entry.id,
        TimeEntriesCompanion(
          startTime: drift.Value(_startTime),
          endTime: drift.Value(_endTime),
          durationSeconds: drift.Value(duration),
        ),
      );
    } else {
      if (_selectedIssue == null) {
        setState(() => _error = 'Select an issue');
        return;
      }
      // Check overlaps
      final overlaps = await dao.getOverlappingEntries(_startTime, _endTime);
      if (overlaps.isNotEmpty) {
        setState(() => _error =
            'Overlaps with ${overlaps.first.issueIdentifier} (${DateFormat('HH:mm').format(overlaps.first.startTime)})');
        return;
      }
      await dao.addManualEntry(
        issueId: _selectedIssue!.issueId,
        issueIdentifier: _selectedIssue!.identifier,
        issueTitle: _selectedIssue!.title,
        teamName: _selectedIssue!.teamName,
        projectName: _selectedIssue!.projectName,
        teamColor: _selectedIssue!.teamColor,
        startTime: _startTime,
        endTime: _endTime,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return MacosAlertDialog(
      appIcon: Icon(
        widget.isEditing
            ? CupertinoIcons.pencil
            : CupertinoIcons.plus_circle,
        size: 48,
        color: AppColors.accent,
      ),
      title: Text(widget.isEditing ? 'Edit Time Entry' : 'Add Manual Entry'),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(widget.date),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: 16),
          // Issue selector (only for new entries)
          if (!widget.isEditing) ...[
            Text(
              'Issue',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 4),
            _IssueSelector(
              selectedIssue: _selectedIssue,
              onChanged: (issue) =>
                  setState(() => _selectedIssue = issue),
            ),
            if (_selectedIssue != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _selectedIssue!.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              widget.existingEntry!.issueIdentifier,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(brightness),
              ),
            ),
            Text(
              widget.existingEntry!.issueTitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Time pickers
          Row(
            children: [
              Expanded(
                child: _TimePicker(
                  label: 'Start',
                  hour: _startHour,
                  minute: _startMinute,
                  onHourChanged: (h) => setState(() => _startHour = h),
                  onMinuteChanged: (m) =>
                      setState(() => _startMinute = m),
                  brightness: brightness,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: AppColors.textTertiary(brightness),
                  ),
                ),
              ),
              Expanded(
                child: _TimePicker(
                  label: 'End',
                  hour: _endHour,
                  minute: _endMinute,
                  onHourChanged: (h) => setState(() => _endHour = h),
                  onMinuteChanged: (m) =>
                      setState(() => _endMinute = m),
                  brightness: brightness,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                ),
              ),
            ),
        ],
      ),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: _save,
        child: Text(widget.isEditing ? 'Save' : 'Add Entry'),
      ),
      secondaryButton: PushButton(
        controlSize: ControlSize.large,
        secondary: true,
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.brightness,
  });

  final String label;
  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(brightness),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: MacosPopupButton<int>(
                value: hour,
                items: List.generate(
                  24,
                  (i) => MacosPopupMenuItem(
                    value: i,
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(brightness),
                ),
              ),
            ),
            Expanded(
              child: MacosPopupButton<int>(
                value: minute,
                items: List.generate(
                  12,
                  (i) => MacosPopupMenuItem(
                    value: i * 5,
                    child: Text((i * 5).toString().padLeft(2, '0')),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onMinuteChanged(v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Simple issue selector dropdown.
class _IssueSelector extends ConsumerWidget {
  const _IssueSelector({
    required this.selectedIssue,
    required this.onChanged,
  });

  final CachedIssue? selectedIssue;
  final ValueChanged<CachedIssue> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(assignedIssuesProvider);

    return issuesAsync.when(
      data: (issues) {
        if (issues.isEmpty) {
          return Text(
            'No issues available',
            style: TextStyle(
              color: AppColors.textTertiary(
                  MacosTheme.of(context).brightness),
            ),
          );
        }
        return MacosPopupButton<String>(
          value: selectedIssue?.issueId,
          hint: const Text('Select issue...'),
          items: issues
              .map((issue) => MacosPopupMenuItem(
                    value: issue.issueId,
                    child: Text(issue.identifier),
                  ))
              .toList(),
          onChanged: (id) {
            if (id != null) {
              final issue = issues.firstWhere((i) => i.issueId == id);
              onChanged(issue);
            }
          },
        );
      },
      loading: () => const ProgressCircle(radius: 8),
      error: (_, _) => const Text('Error loading issues'),
    );
  }
}
