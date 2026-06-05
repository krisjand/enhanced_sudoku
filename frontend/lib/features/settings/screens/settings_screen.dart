import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Settings — coming soon'), dense: true),
          const Divider(),
          ListTile(
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
