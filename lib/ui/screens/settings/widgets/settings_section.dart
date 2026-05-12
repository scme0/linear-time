import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/theme/app_theme.dart';

/// Reusable section header + content wrapper for settings.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textSecondary(brightness),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border(brightness),
              width: 0.5,
            ),
          ),
          child: Column(
            children: _buildChildren(brightness),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildChildren(Brightness brightness) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        // Divider between rows
        result.add(Container(
          height: 0.5,
          margin: const EdgeInsets.only(left: 14),
          color: AppColors.border(brightness),
        ));
      }
    }
    return result;
  }
}

/// A single setting row with label, optional description, and a control widget.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.description,
    required this.control,
  });

  final String label;
  final String? description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }
}
