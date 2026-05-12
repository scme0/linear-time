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
  });

  final IssueFilter filter;
  final ValueChanged<IssueFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  State<IssueSearchBar> createState() => _IssueSearchBarState();
}

class _IssueSearchBarState extends State<IssueSearchBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            ),
          ),
        ],
      ),
    );
  }
}
