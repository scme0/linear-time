import 'package:flutter/services.dart';

/// Manages global hotkey registration via native method channel.
class HotkeyService {
  static const _channel = MethodChannel('com.lineartime/system');
  static VoidCallback? _onHotkeyPressed;

  /// Initialize the listener for hotkey events from native.
  static void init({required VoidCallback onHotkeyPressed}) {
    _onHotkeyPressed = onHotkeyPressed;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onGlobalHotkey') {
        _onHotkeyPressed?.call();
      }
    });
  }

  /// Register a global hotkey.
  static Future<void> setHotkey({
    required int keyCode,
    required int modifiers,
  }) async {
    await _channel.invokeMethod('setGlobalHotkey', {
      'keyCode': keyCode,
      'modifiers': modifiers,
    });
  }

  /// Clear the global hotkey.
  static Future<void> clearHotkey() async {
    await _channel.invokeMethod('clearGlobalHotkey');
  }

  /// Bring the app window to front.
  static Future<void> bringToFront() async {
    await _channel.invokeMethod('bringToFront');
  }
}

/// Common key codes for macOS.
class MacKeyCode {
  static const int t = 17;
  static const int s = 1;
  static const int p = 35;
  static const int space = 49;
}

/// Modifier flag values matching NSEvent.ModifierFlags.rawValue.
class MacModifier {
  static const int command = 1 << 20;  // 0x100000
  static const int shift = 1 << 17;    // 0x020000
  static const int control = 1 << 18;  // 0x040000
  static const int option = 1 << 19;   // 0x080000
}

/// Describes a hotkey combination.
class HotkeyCombo {
  const HotkeyCombo({required this.keyCode, required this.modifiers});

  final int keyCode;
  final int modifiers;

  /// Parse from settings string like "ctrl+shift+17".
  factory HotkeyCombo.fromString(String s) {
    final parts = s.split('+');
    int mods = 0;
    int key = 0;
    for (final part in parts) {
      switch (part.trim().toLowerCase()) {
        case 'cmd':
        case 'command':
          mods |= MacModifier.command;
        case 'ctrl':
        case 'control':
          mods |= MacModifier.control;
        case 'shift':
          mods |= MacModifier.shift;
        case 'opt':
        case 'option':
        case 'alt':
          mods |= MacModifier.option;
        default:
          key = int.tryParse(part.trim()) ?? 0;
      }
    }
    return HotkeyCombo(keyCode: key, modifiers: mods);
  }

  /// Convert to settings string.
  String toSettingsString() {
    final parts = <String>[];
    if (modifiers & MacModifier.control != 0) parts.add('ctrl');
    if (modifiers & MacModifier.shift != 0) parts.add('shift');
    if (modifiers & MacModifier.option != 0) parts.add('opt');
    if (modifiers & MacModifier.command != 0) parts.add('cmd');
    parts.add('$keyCode');
    return parts.join('+');
  }

  /// Human-readable label.
  String toDisplayString() {
    final parts = <String>[];
    if (modifiers & MacModifier.control != 0) parts.add('⌃');
    if (modifiers & MacModifier.option != 0) parts.add('⌥');
    if (modifiers & MacModifier.shift != 0) parts.add('⇧');
    if (modifiers & MacModifier.command != 0) parts.add('⌘');
    parts.add(_keyName(keyCode));
    return parts.join('');
  }

  static String _keyName(int keyCode) {
    return switch (keyCode) {
      0 => 'A', 1 => 'S', 2 => 'D', 3 => 'F', 4 => 'H', 5 => 'G',
      6 => 'Z', 7 => 'X', 8 => 'C', 9 => 'V', 11 => 'B', 12 => 'Q',
      13 => 'W', 14 => 'E', 15 => 'R', 16 => 'Y', 17 => 'T', 18 => '1',
      19 => '2', 20 => '3', 21 => '4', 22 => '6', 23 => '5', 24 => '=',
      25 => '9', 26 => '7', 27 => '-', 28 => '8', 29 => '0', 31 => 'O',
      32 => 'U', 34 => 'I', 35 => 'P', 37 => 'L', 38 => 'J', 40 => 'K',
      45 => 'N', 46 => 'M', 49 => 'Space',
      _ => '?',
    };
  }
}
