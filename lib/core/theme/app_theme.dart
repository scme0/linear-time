import 'package:flutter/cupertino.dart';

/// Softer color palette for the app.
abstract class AppColors {
  // Light theme
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE5E5E5);
  static const lightHover = Color(0xFFF0F0F0);
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightTextTertiary = Color(0xFF999999);

  // Dark theme
  static const darkBackground = Color(0xFF1E1E1E);
  static const darkSurface = Color(0xFF2A2A2A);
  static const darkBorder = Color(0xFF3A3A3A);
  static const darkHover = Color(0xFF333333);
  static const darkTextPrimary = Color(0xFFE5E5E5);
  static const darkTextSecondary = Color(0xFFA0A0A0);
  static const darkTextTertiary = Color(0xFF777777);

  // Accent colors (softer)
  static const activeGreen = Color(0xFF34C759);
  static const activeGreenBgLight = Color(0xFFE8F8EC);
  static const activeGreenBgDark = Color(0xFF1A2E1F);
  static const accentBlue = Color(0xFF5B8DEF);
  static const destructiveRed = Color(0xFFEF5B5B);

  // Status colors
  static const statusStarted = Color(0xFF5B8DEF);
  static const statusCompleted = Color(0xFF34C759);
  static const statusCancelled = Color(0xFF999999);
  static const statusBacklog = Color(0xFFBBBBBB);
  static const statusUnstarted = Color(0xFFE8A84C);

  // Issue colors for calendar stripes (deterministic palette)
  static const issuePalette = [
    Color(0xFF5B8DEF), // blue
    Color(0xFF34C759), // green
    Color(0xFFE8A84C), // amber
    Color(0xFFEF5B5B), // red
    Color(0xFF9B59B6), // purple
    Color(0xFF1ABC9C), // teal
    Color(0xFFE67E22), // orange
    Color(0xFF3498DB), // sky blue
    Color(0xFFE91E63), // pink
    Color(0xFF2ECC71), // emerald
    Color(0xFF8E44AD), // deep purple
    Color(0xFF16A085), // dark teal
  ];

  /// Get a deterministic color for an issue based on its ID.
  static Color colorForIssue(String issueId) {
    final hash = issueId.hashCode.abs();
    return issuePalette[hash % issuePalette.length];
  }

  /// Resolve colors based on brightness.
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color hover(Brightness brightness) =>
      brightness == Brightness.dark ? darkHover : lightHover;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextTertiary : lightTextTertiary;

  static Color activeTimerBg(Brightness brightness) =>
      brightness == Brightness.dark ? activeGreenBgDark : activeGreenBgLight;
}
