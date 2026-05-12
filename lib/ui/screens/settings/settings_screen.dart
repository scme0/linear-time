import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../data/api/linear_api_client.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _testing = false;
  String? _testResult;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final client = LinearApiClient(apiKey: key);
      final viewer = await client.fetchViewer();
      if (viewer != null) {
        await setApiKey(ref, key);
        ref.invalidate(issueRepositoryProvider);
        ref.invalidate(syncIssuesProvider);
        setState(() {
          _testResult = 'Connected as ${viewer['name']} (${viewer['email']})';
        });
      } else {
        setState(() => _testResult = 'Failed — invalid API key');
      }
    } catch (e) {
      setState(() => _testResult = 'Error: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _disconnect() async {
    final repo = ref.read(issueRepositoryProvider);
    await repo?.clearCache();
    await setApiKey(ref, null);
    _apiKeyController.clear();
    setState(() => _testResult = null);
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyProvider);
    final isConnected = apiKey.valueOrNull != null;
    final brightness = MacosTheme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linear Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 12),
          if (isConnected) ...[
            Row(
              children: [
                const Icon(CupertinoIcons.check_mark_circled_solid,
                    color: AppColors.activeGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Connected to Linear',
                  style: TextStyle(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 4),
              Text(
                _testResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(brightness),
                ),
              ),
            ],
            const SizedBox(height: 12),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _disconnect,
              child: const Text('Disconnect'),
            ),
          ] else ...[
            Text(
              'Enter your Linear API key to connect:',
              style: TextStyle(
                color: AppColors.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 400,
              child: MacosTextField(
                controller: _apiKeyController,
                placeholder: 'lin_api_...',
                obscureText: true,
              ),
            ),
            const SizedBox(height: 12),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: _testing ? null : _testConnection,
              child: _testing
                  ? const ProgressCircle(radius: 8)
                  : const Text('Connect'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.startsWith('Connected')
                      ? AppColors.activeGreen
                      : AppColors.destructiveRed,
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
          Text(
            'More settings coming soon...',
            style: TextStyle(color: AppColors.textTertiary(brightness)),
          ),
          const Spacer(),
          // Version at bottom
          Text(
            'Linear Time v0.0.1',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
