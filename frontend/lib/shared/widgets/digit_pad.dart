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

  @override
  Widget build(BuildContext context) {
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
              color: GameColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: canRedo ? onRedo : null,
              color: GameColors.primary,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: Icon(
                isNotesMode ? Icons.edit : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(isNotesMode ? 'Notes on' : 'Notes off'),
              style: TextButton.styleFrom(
                foregroundColor: isNotesMode
                    ? GameColors.primary
                    : GameColors.noteText,
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: isHighlightMode ? null : onToggleNotes,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.highlight),
              tooltip: 'Highlight digit',
              onPressed: onToggleHighlight,
              color: isHighlightMode ? GameColors.primary : GameColors.noteText,
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
    final enabled = onTap != null;
    return Material(
      color: enabled ? GameColors.digitPadButton : GameColors.background,
      borderRadius: BorderRadius.circular(6),
      elevation: enabled ? 2 : 0,
      shadowColor: GameColors.gridLineHeavy.withValues(alpha: 0.3),
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
                color: enabled ? GameColors.clueDigit : GameColors.noteText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
