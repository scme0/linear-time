import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'providers/settings_providers.dart';
import 'ui/app_window.dart';

class LinearTimeApp extends ConsumerWidget {
  const LinearTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode = settingsAsync.valueOrNull?.flutterThemeMode ?? ThemeMode.system;

    return MacosApp(
      title: 'Linear Time',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: themeMode,
      home: const AppWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
