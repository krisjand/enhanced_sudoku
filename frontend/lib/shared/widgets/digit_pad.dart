import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

class DigitPad extends StatelessWidget {
  const DigitPad({
    super.key,
    required this.onDigitTap,
    required this.onToggleNotes,
    required this.isNotesMode,
    required this.isEnabled,
    required this.onUndo,
    required this.canUndo,
    required this.onRedo,
    required this.canRedo,
    required this.onToggleHighlight,
    required this.isHighlightMode,
    required this.onAutoFillNotes,
  });

  final void Function(int digit) onDigitTap;
  final VoidCallback onToggleNotes;
  final bool isNotesMode;
  final bool isEnabled;
  final VoidCallback onUndo;
  final bool canUndo;
  final VoidCallback onRedo;
  final bool canRedo;
  final VoidCallback onToggleHighlight;
  final bool isHighlightMode;
  final VoidCallback onAutoFillNotes;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<GameColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(9, (i) {
            final digit = i + 1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _DigitButton(
                    digit: digit,
                    onTap: isEnabled ? () => onDigitTap(digit) : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo ? onUndo : null,
              color: c.primary,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: canRedo ? onRedo : null,
              color: c.primary,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: Icon(
                isNotesMode ? Icons.edit : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(isNotesMode ? 'Notes on' : 'Notes off'),
              style: TextButton.styleFrom(
                foregroundColor: isNotesMode ? c.primary : c.noteText,
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: onToggleNotes,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.highlight),
              tooltip: 'Highlight digit',
              onPressed: onToggleHighlight,
              color: isHighlightMode ? c.primary : c.noteText,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Auto-fill'),
              style: TextButton.styleFrom(
                foregroundColor: c.noteText,
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: onAutoFillNotes,
            ),
          ],
        ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({required this.digit, this.onTap});

  final int digit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<GameColors>()!;
    final enabled = onTap != null;
    return Material(
      color: enabled ? c.digitPadButton : c.background,
      borderRadius: BorderRadius.circular(6),
      elevation: enabled ? 2 : 0,
      shadowColor: c.gridLineHeavy.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: constraints.maxWidth * 0.55,
                fontWeight: FontWeight.w600,
                color: enabled ? c.clueDigit : c.noteText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
