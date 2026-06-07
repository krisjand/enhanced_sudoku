import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/utils/technique_descriptions.dart';
import '../../../shared/utils/technique_names.dart';
import '../providers/tutorial_provider.dart';

class _Group {
  const _Group(this.label, this.entries);
  final String label;
  final List<(String id, bool enabled)> entries;
}

const _groups = [
  _Group('Basics', [
    ('notes', true),
    ('nakedSingles', true),
    ('hiddenSingles', true),
  ]),
  _Group('Intermediate', [
    ('lockedCandidates', true),
    ('nakedPairs', false),
    ('hiddenPairs', false),
    ('nakedTriples', false),
    ('hiddenTriples', false),
    ('nakedQuadruples', false),
    ('hiddenQuadruples', false),
  ]),
  _Group('Advanced', [
    ('xWing', false),
    ('swordfish', false),
    ('xyWing', false),
    ('xyzWing', false),
  ]),
  _Group('Expert', []),
  _Group('Master', [('forcedChains', false)]),
];

class TutorialListScreen extends ConsumerWidget {
  const TutorialListScreen({super.key});

  void _openLesson(BuildContext context, String id) {
    if (id == 'notes') {
      context.push(AppRoutes.tutorialNotes);
    } else {
      context.push(AppRoutes.tutorialLesson(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedLessonsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final group in _groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                group.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (group.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Coming soon',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              )
            else
              for (final (id, enabled) in group.entries)
                _TechniqueEntry(
                  id: id,
                  enabled: enabled,
                  completed: completed.contains(id),
                  onTap: enabled ? () => _openLesson(context, id) : null,
                ),
          ],
        ],
      ),
    );
  }
}

class _TechniqueEntry extends StatelessWidget {
  const _TechniqueEntry({
    required this.id,
    required this.enabled,
    required this.completed,
    this.onTap,
  });

  final String id;
  final bool enabled;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = enabled ? null : theme.disabledColor;

    return ListTile(
      title: Text(
        techniqueDisplayName(id),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        techniqueDescription(id),
        style: TextStyle(color: textColor),
      ),
      trailing: completed
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : enabled
          ? const Icon(Icons.chevron_right)
          : null,
      onTap: onTap,
    );
  }
}
