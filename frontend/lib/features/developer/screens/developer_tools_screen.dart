import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../shared/providers/error_log_provider.dart';
import '../../../shared/providers/settings_provider.dart';

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

class DeveloperToolsScreen extends ConsumerWidget {
  const DeveloperToolsScreen({super.key});

  Future<void> _ping(BuildContext context, WidgetRef ref) async {
    final baseUrl = ref.read(settingsProvider).backendUrl;
    final url = Uri.parse(
      '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/health',
    );
    final logger = ref.read(errorLogProvider.notifier);
    logger.log('Pinging $url');
    try {
      final response = await http.get(url);
      logger.log(
        'Ping OK ${response.statusCode}',
        'Headers: ${response.headers}\nBody: ${response.body}',
      );
    } on Exception catch (e) {
      logger.log('Ping failed: ${e.runtimeType}', e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(errorLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer tools'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear log',
              onPressed: () => ref.read(errorLogProvider.notifier).clear(),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Backend: ${ref.watch(settingsProvider).backendUrl}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.wifi_tethering, size: 16),
                  label: const Text('Ping'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _ping(context, ref),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No errors logged.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = entries[entries.length - 1 - i]; // newest first
                      return ExpansionTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        title: Text(
                          e.message,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          _fmt(e.timestamp),
                          style: const TextStyle(fontSize: 11),
                        ),
                        children: [
                          if (e.details != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: SelectableText(
                                e.details!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
