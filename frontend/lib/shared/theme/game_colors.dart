import 'package:flutter/material.dart';

// Color palette for the game board. Registered as a ThemeExtension so
// widgets read live values via Theme.of(context).extension<GameColors>()!
// without needing constructor parameters threaded through the widget tree.
//
// Fields marked [configurable] are exposed on the Settings › Colors tab.
// Fields without that marker are fixed structural/brand values.
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    // Background & surface — fixed
    this.background = const Color(0xFFF8F9FA),
    this.surface = const Color(0xFFFFFFFF),
    // Accent / brand — fixed
    this.primary = const Color(0xFF2B6CB0),
    // Grid lines — fixed
    this.gridLineLight = const Color(0xFF94A3B8),
    this.gridLineHeavy = const Color(0xFF2D3748),
    // Digits
    this.clueDigit = const Color(0xFF1A202C),
    this.userDigit = const Color(0xFF2B6CB0), // [configurable]
    this.errorDigit = const Color(0xFFE53E3E),
    this.noteText = const Color(0xFF718096), // [configurable] greyscale
    // Cell states
    this.selectedCell = const Color(0xFF90CAF9), // [configurable] + alpha
    this.peerCell = const Color(0xFFD1D5DB), // [configurable] + alpha
    this.highlightedDigit = const Color(0xFFF6E05E),
    // Digit pad
    this.digitPadButton = const Color(0xFFE2E8F0),
    // Tutorial / hint overlay
    this.sourceCell = const Color(0xFFC6F6D5),
    this.actionCell = const Color(0xFFFEB2B2),
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color gridLineLight;
  final Color gridLineHeavy;
  final Color clueDigit;
  final Color userDigit;
  final Color errorDigit;
  final Color noteText;
  final Color selectedCell;
  final Color peerCell;
  final Color highlightedDigit;
  final Color digitPadButton;
  final Color sourceCell;
  final Color actionCell;

  // Canonical defaults — used as fallback and as base for copyWith.
  static const GameColors defaults = GameColors();

  @override
  GameColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? gridLineLight,
    Color? gridLineHeavy,
    Color? clueDigit,
    Color? userDigit,
    Color? errorDigit,
    Color? noteText,
    Color? selectedCell,
    Color? peerCell,
    Color? highlightedDigit,
    Color? digitPadButton,
    Color? sourceCell,
    Color? actionCell,
  }) => GameColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    primary: primary ?? this.primary,
    gridLineLight: gridLineLight ?? this.gridLineLight,
    gridLineHeavy: gridLineHeavy ?? this.gridLineHeavy,
    clueDigit: clueDigit ?? this.clueDigit,
    userDigit: userDigit ?? this.userDigit,
    errorDigit: errorDigit ?? this.errorDigit,
    noteText: noteText ?? this.noteText,
    selectedCell: selectedCell ?? this.selectedCell,
    peerCell: peerCell ?? this.peerCell,
    highlightedDigit: highlightedDigit ?? this.highlightedDigit,
    digitPadButton: digitPadButton ?? this.digitPadButton,
    sourceCell: sourceCell ?? this.sourceCell,
    actionCell: actionCell ?? this.actionCell,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    return GameColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      gridLineLight: Color.lerp(gridLineLight, other.gridLineLight, t)!,
      gridLineHeavy: Color.lerp(gridLineHeavy, other.gridLineHeavy, t)!,
      clueDigit: Color.lerp(clueDigit, other.clueDigit, t)!,
      userDigit: Color.lerp(userDigit, other.userDigit, t)!,
      errorDigit: Color.lerp(errorDigit, other.errorDigit, t)!,
      noteText: Color.lerp(noteText, other.noteText, t)!,
      selectedCell: Color.lerp(selectedCell, other.selectedCell, t)!,
      peerCell: Color.lerp(peerCell, other.peerCell, t)!,
      highlightedDigit: Color.lerp(
        highlightedDigit,
        other.highlightedDigit,
        t,
      )!,
      digitPadButton: Color.lerp(digitPadButton, other.digitPadButton, t)!,
      sourceCell: Color.lerp(sourceCell, other.sourceCell, t)!,
      actionCell: Color.lerp(actionCell, other.actionCell, t)!,
    );
  }
}
