import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({this.backendUrl = 'http://localhost:8080'});

  final String backendUrl;

  SettingsState copyWith({String? backendUrl}) =>
      SettingsState(backendUrl: backendUrl ?? this.backendUrl);
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setBackendUrl(String url) => state = state.copyWith(backendUrl: url);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
