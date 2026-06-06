import 'lesson_board.dart';

class TutorialLesson {
  const TutorialLesson({
    required this.technique,
    required this.explain,
    required this.practice,
  });

  final String technique;
  final LessonBoard explain;
  final List<LessonBoard> practice;

  factory TutorialLesson.fromJson(Map<String, dynamic> json) => TutorialLesson(
    technique: json['technique'] as String,
    explain: LessonBoard.fromJson(json['explain'] as Map<String, dynamic>),
    practice: (json['practice'] as List? ?? [])
        .map((e) => LessonBoard.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class NotesLesson {
  const NotesLesson({required this.practice});
  final LessonBoard practice;

  factory NotesLesson.fromJson(Map<String, dynamic> json) => NotesLesson(
    practice: LessonBoard.fromJson(json['practice'] as Map<String, dynamic>),
  );
}
