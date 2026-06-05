import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    this.backendUrl = 'http://localhost:8080',
    this.autoRemoveNotes = true,
  });

  final String backendUrl;

  // When true, placing a digit removes that digit from the notes of all peer
  // cells (same row, column, and box) in the same undo step.
  final bool autoRemoveNotes;

  SettingsState copyWith({String? backendUrl, bool? autoRemoveNotes}) =>
      SettingsState(
        backendUrl: backendUrl ?? this.backendUrl,
        autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setBackendUrl(String url) => state = state.copyWith(backendUrl: url);

  void setAutoRemoveNotes(bool value) =>
      state = state.copyWith(autoRemoveNotes: value);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
