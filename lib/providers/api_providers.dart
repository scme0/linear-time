import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api/linear_api_client.dart';

const _apiKeyStorageKey = 'linear_api_key';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// The stored API key (read from secure storage).
final apiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: _apiKeyStorageKey);
});

/// Save or remove the API key.
Future<void> setApiKey(WidgetRef ref, String? apiKey) async {
  final storage = ref.read(secureStorageProvider);
  if (apiKey == null || apiKey.isEmpty) {
    await storage.delete(key: _apiKeyStorageKey);
  } else {
    await storage.write(key: _apiKeyStorageKey, value: apiKey);
  }
  ref.invalidate(apiKeyProvider);
}

/// Linear API client — null if no API key configured.
final linearApiClientProvider = Provider<LinearApiClient?>((ref) {
  final apiKeyAsync = ref.watch(apiKeyProvider);
  return apiKeyAsync.whenOrNull(
    data: (key) => key != null ? LinearApiClient(apiKey: key) : null,
  );
});
