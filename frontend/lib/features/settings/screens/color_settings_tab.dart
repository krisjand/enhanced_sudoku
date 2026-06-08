import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/sudoku_grid.dart';

// Fixed preview board — standard easy puzzle so every unit is represented,
// with notes pre-filled so all colors are visible at once.
const _previewGrid = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  [0, 9, 8, 0, 0, 0, 0, 6, 0],
  [8, 0, 0, 0, 6, 0, 0, 0, 3],
  [4, 0, 0, 8, 0, 3, 0, 0, 1],
  [7, 0, 0, 0, 2, 0, 0, 0, 6],
  [0, 6, 0, 0, 0, 0, 2, 8, 0],
  [0, 0, 0, 4, 1, 9, 0, 0, 5],
  [0, 0, 0, 0, 8, 0, 0, 7, 9],
];

// Notes for empty cells so the preview shows note text colour.
// Computed once — the preview grid never changes.
final _previewNotes = List.generate(
  9,
  (r) => List.generate(9, (c) {
    if (_previewGrid[r][c] != 0) return <int>{};
    final d = (r + c) % 9 + 1;
    final d2 = (r * 2 + c + 3) % 9 + 1;
    return {d, if (d2 != d) d2};
  }),
);

final _previewState = GameState(
  initialGrid: _previewGrid,
  currentGrid: _previewGrid,
  notes: _previewNotes,
);

class ColorSettingsTab extends ConsumerStatefulWidget {
  const ColorSettingsTab({super.key});

  @override
  ConsumerState<ColorSettingsTab> createState() => _ColorSettingsTabState();
}

class _ColorSettingsTabState extends ConsumerState<ColorSettingsTab> {
  static const _previewSelRow = 1;
  static const _previewSelCol = 1;

  void _pickColor({
    required String title,
    required Color current,
    required bool withAlpha,
    required void Function(Color) onChanged,
  }) {
    Color working = current;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: withAlpha
              ? ColorPicker(
                  pickerColor: working,
                  onColorChanged: (c) => working = c,
                  enableAlpha: true,
                  labelTypes: const [],
                )
              : _GreyscalePicker(color: working, onChanged: (c) => working = c),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onChanged(working);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Live preview board ──────────────────────────────────────────────
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: _previewState,
            selectedRow: _previewSelRow,
            selectedCol: _previewSelCol,
            isHighlightMode: true,
          ),
        ),
        const SizedBox(height: 20),

        // ── Preset themes ───────────────────────────────────────────────────
        Text('Presets', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colorThemes.map((t) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(t.label),
                  avatar: CircleAvatar(backgroundColor: t.selectedCell),
                  onPressed: () => notifier.applyTheme(t),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Individual pickers ──────────────────────────────────────────────
        Text('Colors', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        _ColorTile(
          label: 'Selected cell',
          subtitle: 'Color and opacity of the active cell',
          color: settings.selectedCellColor,
          onTap: () => _pickColor(
            title: 'Selected cell',
            current: settings.selectedCellColor,
            withAlpha: true,
            onChanged: notifier.setSelectedCellColor,
          ),
        ),
        _ColorTile(
          label: 'Input numbers',
          subtitle: 'Color of digits you place',
          color: settings.userDigitColor,
          onTap: () => _pickColor(
            title: 'Input numbers',
            current: settings.userDigitColor,
            withAlpha: false,
            onChanged: notifier.setUserDigitColor,
          ),
        ),
        _ColorTile(
          label: 'Notes',
          subtitle: 'Greyscale brightness of candidate digits',
          color: settings.noteTextColor,
          onTap: () => _pickColor(
            title: 'Notes',
            current: settings.noteTextColor,
            withAlpha: false,
            onChanged: notifier.setNoteTextColor,
          ),
        ),
        _ColorTile(
          label: 'Affected cells',
          subtitle: 'Color and opacity of peer cells',
          color: settings.peerCellColor,
          onTap: () => _pickColor(
            title: 'Affected cells',
            current: settings.peerCellColor,
            withAlpha: true,
            onChanged: notifier.setPeerCellColor,
          ),
        ),
      ],
    );
  }
}

// ── Color swatch list tile ────────────────────────────────────────────────────

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Greyscale picker (brightness slider only) ─────────────────────────────────

class _GreyscalePicker extends StatefulWidget {
  const _GreyscalePicker({required this.color, required this.onChanged});

  final Color color;
  final void Function(Color) onChanged;

  @override
  State<_GreyscalePicker> createState() => _GreyscalePickerState();
}

class _GreyscalePickerState extends State<_GreyscalePicker> {
  late double _brightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.color);
    _brightness = hsl.lightness;
  }

  @override
  Widget build(BuildContext context) {
    final grey = Color.fromARGB(
      255,
      (_brightness * 255).round(),
      (_brightness * 255).round(),
      (_brightness * 255).round(),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: grey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.circle, size: 16, color: Colors.black),
            Expanded(
              child: Slider(
                value: _brightness,
                onChanged: (v) {
                  setState(() => _brightness = v);
                  widget.onChanged(
                    Color.fromARGB(
                      255,
                      (v * 255).round(),
                      (v * 255).round(),
                      (v * 255).round(),
                    ),
                  );
                },
              ),
            ),
            const Icon(Icons.circle, size: 16, color: Colors.white),
          ],
        ),
      ],
    );
  }
}
