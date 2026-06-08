import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/settings_provider.dart';

const _backendUrls = [
  ('localhost:8080', 'http://localhost:8080'),
  ('Android emulator', 'http://10.0.2.2:8080'),
];

class LogicSettingsTab extends ConsumerWidget {
  const LogicSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-remove notes'),
          subtitle: const Text(
            'Automatically eliminate candidate digits when a cell is filled',
          ),
          value: settings.autoRemoveNotes,
          onChanged: notifier.setAutoRemoveNotes,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Highlight mode on by default'),
          subtitle: const Text(
            'Highlight peers and matching digits when a cell is selected',
          ),
          value: settings.highlightModeDefault,
          onChanged: notifier.setHighlightModeDefault,
        ),
        const Divider(height: 32),
        const Text('Backend URL'),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: settings.backendUrl,
          isExpanded: true,
          underline: const Divider(height: 1),
          items: _backendUrls.map((entry) {
            final (label, url) = entry;
            return DropdownMenuItem(value: url, child: Text(label));
          }).toList(),
          onChanged: (url) {
            if (url != null) notifier.setBackendUrl(url);
          },
        ),
      ],
    );
  }
}
