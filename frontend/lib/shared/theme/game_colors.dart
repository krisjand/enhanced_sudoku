import 'package:flutter/material.dart';

// Default color palette for the game board.
//
// Colors marked [configurable] are intended to be user-adjustable via the
// Settings screen (story #90). The values here are the shipped defaults.
// Non-configurable colors are fixed brand/structural values.
abstract final class GameColors {
  // Background & surface — fixed
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);

  // Accent / brand — fixed
  static const primary = Color(0xFF2B6CB0);

  // Grid lines — [configurable]
  static const gridLineLight = Color(0xFF94A3B8);
  static const gridLineHeavy = Color(0xFF2D3748);

  // Digits — [configurable]
  static const clueDigit = Color(0xFF1A202C);
  static const userDigit = Color(0xFF2B6CB0);
  static const errorDigit = Color(0xFFE53E3E);
  static const noteText = Color(0xFF718096);

  // Cell states — [configurable]
  static const selectedCell = Color(0xFF90CAF9);
  static const peerCell = Color(0xFFD1D5DB);
  static const highlightedDigit = Color(0xFFF6E05E);

  // Digit pad — [configurable]
  static const digitPadButton = Color(0xFFE2E8F0); // cool light grey

  // Hint overlay — [configurable]
  static const sourceCell = Color(0xFFC6F6D5);
  static const actionCell = Color(0xFFFEB2B2);
}
