import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorLogEntry {
  ErrorLogEntry({required this.message, this.details})
    : timestamp = DateTime.now();

  final DateTime timestamp;
  final String message;
  final String? details;
}

class ErrorLogNotifier extends Notifier<List<ErrorLogEntry>> {
  static const _maxEntries = 200;

  @override
  List<ErrorLogEntry> build() => [];

  void log(String message, [Object? error]) {
    final details = error?.toString();
    dev.log(message, error: error, name: 'AppError');
    final entry = ErrorLogEntry(message: message, details: details);
    final updated = [...state, entry];
    state = updated.length > _maxEntries
        ? updated.sublist(updated.length - _maxEntries)
        : updated;
  }

  void clear() => state = [];
}

final errorLogProvider =
    NotifierProvider<ErrorLogNotifier, List<ErrorLogEntry>>(
      ErrorLogNotifier.new,
    );
