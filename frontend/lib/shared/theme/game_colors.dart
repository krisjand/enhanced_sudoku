import 'package:flutter/material.dart';

abstract final class GameColors {
  // Background & surface
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);

  // Accent / brand
  static const primary = Color(0xFF2B6CB0);

  // Grid lines
  static const gridLineLight = Color(0xFFCBD5E0);
  static const gridLineHeavy = Color(0xFF2D3748);

  // Digits
  static const clueDigit = Color(0xFF1A202C);
  static const userDigit = Color(0xFF2B6CB0);
  static const errorDigit = Color(0xFFE53E3E);
  static const noteText = Color(0xFF718096);

  // Cell states
  static const selectedCell = Color(0xFF90CAF9); // Material Blue 200
  static const peerCell = Color(0xFFD1D5DB); // neutral grey
  static const highlightedDigit = Color(0xFFF6E05E);

  // Hint overlay
  static const sourceCell = Color(0xFFC6F6D5);
  static const actionCell = Color(0xFFFEB2B2);
}
