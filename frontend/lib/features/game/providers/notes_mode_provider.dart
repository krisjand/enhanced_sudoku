import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final notesModeProvider = NotifierProvider<NotesModeNotifier, bool>(
  NotesModeNotifier.new,
);
