import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/tutorial_lesson.dart';

// Loads a TutorialLesson asset for the given technique identifier.
final tutorialLessonProvider = FutureProvider.autoDispose
    .family<TutorialLesson, String>((ref, technique) async {
      final raw = await rootBundle.loadString(
        'assets/tutorial/$technique.json',
      );
      return TutorialLesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });

// Loads the notes lesson asset.
final notesLessonProvider = FutureProvider.autoDispose<NotesLesson>((
  ref,
) async {
  final raw = await rootBundle.loadString('assets/tutorial/notes.json');
  return NotesLesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

// Tracks which lessons the user has completed this session (in-memory).
class CompletedLessonsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markComplete(String lessonKey) => state = {...state, lessonKey};

  bool isComplete(String lessonKey) => state.contains(lessonKey);
}

final completedLessonsProvider =
    NotifierProvider<CompletedLessonsNotifier, Set<String>>(
      CompletedLessonsNotifier.new,
    );
