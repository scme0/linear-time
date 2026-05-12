import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'ui/app_window.dart';

class LinearTimeApp extends ConsumerWidget {
  const LinearTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacosApp(
      title: 'Linear Time',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const AppWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
