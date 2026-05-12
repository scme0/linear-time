import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../data/api/linear_api_client.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/issue_providers.dart';
import '../../../providers/repository_providers.dart';

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
        // Trigger initial sync after connecting
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
    // Clear cached issues before disconnecting
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

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Settings'),
        titleWidth: 150,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Linear Connection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (isConnected) ...[
                    const Row(
                      children: [
                        Icon(CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.activeGreen),
                        SizedBox(width: 8),
                        Text('Connected to Linear'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PushButton(
                      controlSize: ControlSize.regular,
                      onPressed: _disconnect,
                      child: const Text('Disconnect'),
                    ),
                  ] else ...[
                    const Text('Enter your Linear API key to connect:'),
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
                  ],
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(_testResult!),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'More settings coming soon...',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
