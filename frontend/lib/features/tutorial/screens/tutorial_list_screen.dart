import 'package:flutter/material.dart';

class TutorialListScreen extends StatelessWidget {
  const TutorialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      body: const Center(child: Text('Tutorial — coming soon')),
    );
  }
}
