import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/time_tracking_repository.dart';
import '../data/repositories/issue_repository.dart';
import 'database_providers.dart';
import 'api_providers.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  return TimeTrackingRepository(
    timeEntryDao: ref.watch(timeEntryDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
  );
});

/// Issue repository — null if Linear not connected.
final issueRepositoryProvider = Provider<IssueRepository?>((ref) {
  final apiClient = ref.watch(linearApiClientProvider);
  if (apiClient == null) return null;
  return IssueRepository(
    apiClient: apiClient,
    cachedIssueDao: ref.watch(cachedIssueDaoProvider),
  );
});
