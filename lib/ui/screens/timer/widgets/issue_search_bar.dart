import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../timer_screen.dart';

class IssueSearchBar extends StatefulWidget {
  const IssueSearchBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    this.onSubmitted,
    this.focusNotifier,
  });

  final IssueFilter filter;
  final ValueChanged<IssueFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onSubmitted;
  final ValueNotifier<int>? focusNotifier;

  @override
  State<IssueSearchBar> createState() => _IssueSearchBarState();
}

class _IssueSearchBarState extends State<IssueSearchBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.focusNotifier?.addListener(_onFocusRequested);
  }

  @override
  void didUpdateWidget(IssueSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNotifier != widget.focusNotifier) {
      oldWidget.focusNotifier?.removeListener(_onFocusRequested);
      widget.focusNotifier?.addListener(_onFocusRequested);
    }
  }

  @override
  void dispose() {
    widget.focusNotifier?.removeListener(_onFocusRequested);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusRequested() {
    _focusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter selector
          MacosPopupButton<IssueFilter>(
            value: widget.filter,
            items: IssueFilter.values
                .map((f) => MacosPopupMenuItem(
                      value: f,
                      child: Text(f.label),
                    ))
                .toList(),
            onChanged: (f) {
              if (f != null) widget.onFilterChanged(f);
            },
          ),
          const SizedBox(width: 12),
          // Search field
          Expanded(
            child: MacosTextField(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: 'Search issues or paste ID/URL...',
              placeholderStyle: TextStyle(
                color: AppColors.textSecondary(brightness),
                fontSize: 13,
              ),
              style: TextStyle(
                color: AppColors.textPrimary(brightness),
                fontSize: 13,
              ),
              onChanged: (value) => widget.onSearchChanged(value),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
