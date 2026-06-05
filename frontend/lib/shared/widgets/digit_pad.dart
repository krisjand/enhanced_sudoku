import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

class DigitPad extends StatelessWidget {
  const DigitPad({
    super.key,
    required this.onDigitTap,
    required this.onToggleNotes,
    required this.isNotesMode,
    required this.isEnabled,
  });

  final void Function(int digit) onDigitTap;
  final VoidCallback onToggleNotes;
  final bool isNotesMode;
  final bool isEnabled;

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
        Center(
          child: TextButton.icon(
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
            onPressed: onToggleNotes,
          ),
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
      color: enabled ? GameColors.surface : GameColors.background,
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
