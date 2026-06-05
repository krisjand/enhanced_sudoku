import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ref.read(settingsProvider).backendUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Backend', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'http://localhost:8080',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (v) => ref
                      .read(settingsProvider.notifier)
                      .setBackendUrl(v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .setBackendUrl(_urlController.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Developer tools'),
            subtitle: const Text('View error log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.developerTools),
          ),
        ],
      ),
    );
  }
}
