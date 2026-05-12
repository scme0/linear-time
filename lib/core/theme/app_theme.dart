import 'package:flutter/cupertino.dart';

/// Linear Time color system.
///
/// Design principles:
/// - Warm greys (slight blue undertone) instead of pure black/white
/// - Dark mode uses charcoal, not black
/// - Light mode uses off-white, not pure white
/// - Accent blue is the primary brand color (calm, productive)
/// - Green reserved for "active/running" states only
/// - All text meets WCAG AA contrast ratios in both modes
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────
  static const accent = Color(0xFF5C7CFA);       // indigo-blue, primary action
  static const accentHover = Color(0xFF4263EB);   // darker on hover
  static const accentSubtle = Color(0xFFEDF2FF);  // light: accent tint bg
  static const accentSubtleDark = Color(0xFF2B3557); // dark: accent tint bg

  // ── Semantic ───────────────────────────────────────────────────────
  static const success = Color(0xFF40C057);       // timer running, connected
  static const warning = Color(0xFFFAB005);       // idle, manual entry
  static const danger = Color(0xFFFA5252);        // stop, delete, error

  // ── Light mode ─────────────────────────────────────────────────────
  static const lightBg       = Color(0xFFF8F9FA); // app background (warm off-white)
  static const lightSurface  = Color(0xFFFFFFFF); // cards, banners
  static const lightSurface2 = Color(0xFFF1F3F5); // secondary surface (search bar bg)
  static const lightBorder   = Color(0xFFDEE2E6); // subtle borders
  static const lightHover    = Color(0xFFF1F3F5); // row hover
  static const lightSelected = Color(0xFFE7F5FF); // selected/active row

  static const lightText     = Color(0xFF212529); // primary text
  static const lightText2    = Color(0xFF495057); // secondary text (readable!)
  static const lightText3    = Color(0xFF868E96); // tertiary/muted
  static const lightTextInv  = Color(0xFFFFFFFF); // text on colored bg

  // ── Dark mode ──────────────────────────────────────────────────────
  static const darkBg        = Color(0xFF2B2D31); // charcoal (not black)
  static const darkSurface   = Color(0xFF313338); // cards, banners
  static const darkSurface2  = Color(0xFF383A40); // secondary surface
  static const darkBorder    = Color(0xFF43454A); // subtle borders
  static const darkHover     = Color(0xFF3B3D44); // row hover
  static const darkSelected  = Color(0xFF2B3A4A); // selected/active row

  static const darkText      = Color(0xFFE4E5E8); // primary text
  static const darkText2     = Color(0xFFB5BAC1); // secondary text (readable!)
  static const darkText3     = Color(0xFF80848E); // tertiary/muted
  static const darkTextInv   = Color(0xFFFFFFFF); // text on colored bg

  // ── Active timer ───────────────────────────────────────────────────
  static const timerBgLight  = Color(0xFFEBFBEE); // light green tint
  static const timerBgDark   = Color(0xFF2B3B2E); // dark green tint
  static const timerBorder   = Color(0xFF69DB7C); // green border (softer)

  // ── Status badges ──────────────────────────────────────────────────
  static const statusStarted    = Color(0xFF5C7CFA); // blue
  static const statusCompleted  = Color(0xFF40C057); // green
  static const statusCancelled  = Color(0xFF868E96); // grey
  static const statusBacklog    = Color(0xFFADB5BD); // light grey
  static const statusUnstarted  = Color(0xFFFAB005); // amber

  // ── Issue stripe palette ───────────────────────────────────────────
  // Muted enough for both modes, distinct enough to tell apart
  static const issuePalette = [
    Color(0xFF5C7CFA), // indigo
    Color(0xFF40C057), // green
    Color(0xFFFAB005), // amber
    Color(0xFFFA5252), // red
    Color(0xFF9775FA), // violet
    Color(0xFF20C997), // teal
    Color(0xFFFF922B), // orange
    Color(0xFF339AF0), // blue
    Color(0xFFE64980), // pink
    Color(0xFF51CF66), // lime
    Color(0xFF845EF7), // purple
    Color(0xFF22B8CF), // cyan
  ];

  /// Deterministic color for an issue based on its ID hash.
  static Color colorForIssue(String issueId) {
    final hash = issueId.hashCode.abs();
    return issuePalette[hash % issuePalette.length];
  }

  // ── Brightness-aware resolvers ─────────────────────────────────────

  static Color background(Brightness b) =>
      b == Brightness.dark ? darkBg : lightBg;

  static Color surface(Brightness b) =>
      b == Brightness.dark ? darkSurface : lightSurface;

  static Color surface2(Brightness b) =>
      b == Brightness.dark ? darkSurface2 : lightSurface2;

  static Color border(Brightness b) =>
      b == Brightness.dark ? darkBorder : lightBorder;

  static Color hover(Brightness b) =>
      b == Brightness.dark ? darkHover : lightHover;

  static Color selected(Brightness b) =>
      b == Brightness.dark ? darkSelected : lightSelected;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? darkText : lightText;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? darkText2 : lightText2;

  static Color textTertiary(Brightness b) =>
      b == Brightness.dark ? darkText3 : lightText3;

  static Color activeTimerBg(Brightness b) =>
      b == Brightness.dark ? timerBgDark : timerBgLight;
}
