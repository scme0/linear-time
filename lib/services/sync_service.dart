import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/issue_providers.dart';

/// Periodically syncs issues from Linear in the background.
class SyncService {
  SyncService(this._ref);

  final WidgetRef _ref;
  Timer? _timer;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // Sync every 60 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _sync(),
    );
  }

  void _sync() {
    _ref.invalidate(syncIssuesProvider);
  }

  void dispose() {
    _timer?.cancel();
  }
}
