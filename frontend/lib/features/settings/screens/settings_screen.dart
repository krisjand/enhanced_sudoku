import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import 'color_settings_tab.dart';
import 'logic_settings_tab.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.palette_outlined), text: 'Colors'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Logic'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.developer_mode_outlined),
              tooltip: 'Developer tools',
              onPressed: () => context.push(AppRoutes.developerTools),
            ),
          ],
        ),
        body: const TabBarView(
          children: [ColorSettingsTab(), LogicSettingsTab()],
        ),
      ),
    );
  }
}
