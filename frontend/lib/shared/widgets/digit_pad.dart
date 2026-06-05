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
    return Row(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: List.generate(
              9,
              (i) => _DigitButton(
                digit: i + 1,
                onTap: isEnabled ? () => onDigitTap(i + 1) : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NotesModeButton(isActive: isNotesMode, onTap: onToggleNotes),
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
      color: enabled ? GameColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: enabled ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: enabled ? GameColors.clueDigit : GameColors.noteText,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesModeButton extends StatelessWidget {
  const _NotesModeButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isActive ? Icons.edit : Icons.edit_outlined,
              color: isActive ? GameColors.primary : GameColors.noteText,
            ),
            onPressed: onTap,
            tooltip: isActive ? 'Notes mode on' : 'Notes mode off',
          ),
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 10,
              color: isActive ? GameColors.primary : GameColors.noteText,
            ),
          ),
        ],
      ),
    );
  }
}
