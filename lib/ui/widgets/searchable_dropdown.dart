import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Colors;
import 'package:macos_ui/macos_ui.dart';

import '../../core/theme/app_theme.dart';

/// A compact dropdown that opens a searchable popup.
/// Shows truncated selected value with ellipsis.
class SearchableDropdown<T> extends StatefulWidget {
  const SearchableDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
    this.hint = 'Select...',
    this.allLabel = 'All',
    this.maxWidth = 120,
  });

  final List<({T id, String name})> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T? value) labelBuilder;
  final String hint;
  final String allLabel;
  final double maxWidth;

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SearchableDropdownOverlay<T>(
        link: _layerLink,
        targetSize: size,
        items: widget.items,
        value: widget.value,
        allLabel: widget.allLabel,
        onSelected: (v) {
          widget.onChanged(v);
          _close();
        },
        onClose: _close,
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final label = widget.value != null
        ? widget.labelBuilder(widget.value)
        : widget.allLabel;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2(brightness),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isOpen
                    ? AppColors.accent
                    : AppColors.border(brightness),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.value != null
                          ? AppColors.textPrimary(brightness)
                          : AppColors.textSecondary(brightness),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 10,
                  color: AppColors.textTertiary(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableDropdownOverlay<T> extends StatefulWidget {
  const _SearchableDropdownOverlay({
    required this.link,
    required this.targetSize,
    required this.items,
    required this.value,
    required this.allLabel,
    required this.onSelected,
    required this.onClose,
  });

  final LayerLink link;
  final Size targetSize;
  final List<({T id, String name})> items;
  final T? value;
  final String allLabel;
  final ValueChanged<T?> onSelected;
  final VoidCallback onClose;

  @override
  State<_SearchableDropdownOverlay<T>> createState() =>
      _SearchableDropdownOverlayState<T>();
}

class _SearchableDropdownOverlayState<T>
    extends State<_SearchableDropdownOverlay<T>> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where(
                (i) => i.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Stack(
      children: [
        // Backdrop to close on outside tap
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Dropdown
        CompositedTransformFollower(
          link: widget.link,
          offset: Offset(0, widget.targetSize.height + 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 220,
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border(brightness),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CupertinoTextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      placeholder: 'Filter...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary(brightness),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface2(brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  // Options
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 4),
                      children: [
                        // "All" option
                        if (_query.isEmpty)
                          _buildOption(
                            label: widget.allLabel,
                            isSelected: widget.value == null,
                            onTap: () => widget.onSelected(null),
                            brightness: brightness,
                          ),
                        // Items
                        ...filtered.map((item) => _buildOption(
                              label: item.name,
                              isSelected: widget.value == item.id,
                              onTap: () => widget.onSelected(item.id),
                              brightness: brightness,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.accent
                  : AppColors.textPrimary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}
