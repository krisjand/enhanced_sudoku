import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/persistence_service.dart';
import '../theme/game_colors.dart';
import 'persistence_provider.dart';

// ── Default configurable colors ───────────────────────────────────────────────

const _defaultSelectedCell = Color(0xFF90CAF9);
const _defaultUserDigit = Color(0xFF2B6CB0);
const _defaultNoteText = Color(0xFF718096);
const _defaultPeerCell = Color(0xFFD1D5DB);

// ── Keys used in SettingsDao ──────────────────────────────────────────────────

const _kBackendUrl = 'backendUrl';
const _kAutoRemoveNotes = 'autoRemoveNotes';
const _kHighlightModeDefault = 'highlightModeDefault';
const _kColorSelectedCell = 'color_selectedCell';
const _kColorUserDigit = 'color_userDigit';
const _kColorNoteText = 'color_noteText';
const _kColorPeerCell = 'color_peerCell';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  const SettingsState({
    this.backendUrl = 'http://localhost:8080',
    this.autoRemoveNotes = true,
    this.highlightModeDefault = true,
    this.selectedCellColor = _defaultSelectedCell,
    this.userDigitColor = _defaultUserDigit,
    this.noteTextColor = _defaultNoteText,
    this.peerCellColor = _defaultPeerCell,
  });

  final String backendUrl;
  final bool autoRemoveNotes;
  // Initial highlight mode state when a new game starts.
  final bool highlightModeDefault;
  // Configurable game-board colors.
  final Color selectedCellColor;
  final Color userDigitColor;
  final Color noteTextColor;
  final Color peerCellColor;

  SettingsState copyWith({
    String? backendUrl,
    bool? autoRemoveNotes,
    bool? highlightModeDefault,
    Color? selectedCellColor,
    Color? userDigitColor,
    Color? noteTextColor,
    Color? peerCellColor,
  }) => SettingsState(
    backendUrl: backendUrl ?? this.backendUrl,
    autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
    highlightModeDefault: highlightModeDefault ?? this.highlightModeDefault,
    selectedCellColor: selectedCellColor ?? this.selectedCellColor,
    userDigitColor: userDigitColor ?? this.userDigitColor,
    noteTextColor: noteTextColor ?? this.noteTextColor,
    peerCellColor: peerCellColor ?? this.peerCellColor,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsState> {
  SettingsDao get _dao => ref.read(persistenceProvider).settingsDao;

  @override
  SettingsState build() {
    // Load from DB asynchronously; UI rebuilds when the future completes.
    Future(_load);
    return const SettingsState();
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    final url = await _dao.get(_kBackendUrl);
    final autoRemove = await _dao.get(_kAutoRemoveNotes);
    final hlDefault = await _dao.get(_kHighlightModeDefault);
    final selCell = await _dao.get(_kColorSelectedCell);
    final userDig = await _dao.get(_kColorUserDigit);
    final noteT = await _dao.get(_kColorNoteText);
    final peerC = await _dao.get(_kColorPeerCell);

    if (!ref.mounted) return;
    state = SettingsState(
      backendUrl: url ?? 'http://localhost:8080',
      autoRemoveNotes: autoRemove != 'false',
      highlightModeDefault: hlDefault != 'false',
      selectedCellColor: selCell != null
          ? Color(int.parse(selCell))
          : _defaultSelectedCell,
      userDigitColor: userDig != null
          ? Color(int.parse(userDig))
          : _defaultUserDigit,
      noteTextColor: noteT != null ? Color(int.parse(noteT)) : _defaultNoteText,
      peerCellColor: peerC != null ? Color(int.parse(peerC)) : _defaultPeerCell,
    );
  }

  Future<void> setBackendUrl(String url) async {
    await _dao.set(_kBackendUrl, url);
    state = state.copyWith(backendUrl: url);
  }

  Future<void> setAutoRemoveNotes(bool value) async {
    await _dao.set(_kAutoRemoveNotes, value.toString());
    state = state.copyWith(autoRemoveNotes: value);
  }

  Future<void> setHighlightModeDefault(bool value) async {
    await _dao.set(_kHighlightModeDefault, value.toString());
    state = state.copyWith(highlightModeDefault: value);
  }

  Future<void> setSelectedCellColor(Color color) async {
    await _dao.set(_kColorSelectedCell, color.toARGB32().toString());
    state = state.copyWith(selectedCellColor: color);
  }

  Future<void> setUserDigitColor(Color color) async {
    await _dao.set(_kColorUserDigit, color.toARGB32().toString());
    state = state.copyWith(userDigitColor: color);
  }

  Future<void> setNoteTextColor(Color color) async {
    await _dao.set(_kColorNoteText, color.toARGB32().toString());
    state = state.copyWith(noteTextColor: color);
  }

  Future<void> setPeerCellColor(Color color) async {
    await _dao.set(_kColorPeerCell, color.toARGB32().toString());
    state = state.copyWith(peerCellColor: color);
  }

  Future<void> applyTheme(ColorTheme theme) async {
    await Future.wait([
      _dao.set(_kColorSelectedCell, theme.selectedCell.toARGB32().toString()),
      _dao.set(_kColorUserDigit, theme.userDigit.toARGB32().toString()),
      _dao.set(_kColorNoteText, theme.noteText.toARGB32().toString()),
      _dao.set(_kColorPeerCell, theme.peerCell.toARGB32().toString()),
    ]);
    state = state.copyWith(
      selectedCellColor: theme.selectedCell,
      userDigitColor: theme.userDigit,
      noteTextColor: theme.noteText,
      peerCellColor: theme.peerCell,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

// ── Derived: GameColors from settings ─────────────────────────────────────────

final gameColorsProvider = Provider<GameColors>((ref) {
  final s = ref.watch(settingsProvider);
  return GameColors.defaults.copyWith(
    selectedCell: s.selectedCellColor,
    userDigit: s.userDigitColor,
    noteText: s.noteTextColor,
    peerCell: s.peerCellColor,
  );
});

// ── Preset themes ─────────────────────────────────────────────────────────────

class ColorTheme {
  const ColorTheme({
    required this.label,
    required this.selectedCell,
    required this.userDigit,
    required this.noteText,
    required this.peerCell,
  });
  final String label;
  final Color selectedCell;
  final Color userDigit;
  final Color noteText;
  final Color peerCell;
}

const List<ColorTheme> colorThemes = [
  ColorTheme(
    label: 'Default',
    selectedCell: _defaultSelectedCell,
    userDigit: _defaultUserDigit,
    noteText: _defaultNoteText,
    peerCell: _defaultPeerCell,
  ),
  ColorTheme(
    label: 'Blues',
    selectedCell: Color(0xFF64B5F6),
    userDigit: Color(0xFF1565C0),
    noteText: Color(0xFF546E7A),
    peerCell: Color(0xFFBBDEFB),
  ),
  ColorTheme(
    label: 'Greens',
    selectedCell: Color(0xFFA5D6A7),
    userDigit: Color(0xFF2E7D32),
    noteText: Color(0xFF558B2F),
    peerCell: Color(0xFFC8E6C9),
  ),
  ColorTheme(
    label: 'Reds',
    selectedCell: Color(0xFFEF9A9A),
    userDigit: Color(0xFFC62828),
    noteText: Color(0xFF78909C),
    peerCell: Color(0xFFFFCDD2),
  ),
  ColorTheme(
    label: 'Warm',
    selectedCell: Color(0xFFFFCC80),
    userDigit: Color(0xFFE65100),
    noteText: Color(0xFF795548),
    peerCell: Color(0xFFFFF3E0),
  ),
  ColorTheme(
    label: 'Cool',
    selectedCell: Color(0xFFB39DDB),
    userDigit: Color(0xFF4527A0),
    noteText: Color(0xFF607D8B),
    peerCell: Color(0xFFEDE7F6),
  ),
];
