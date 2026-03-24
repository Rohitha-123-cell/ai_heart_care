import 'package:flutter/foundation.dart';

/// Base class for all Patient BLoC events
@immutable
abstract class PatientEvent {}

/// Event fired when user selects an answer for a question
class SelectAnswer extends PatientEvent {
  final String questionId;
  final String answer;

  SelectAnswer({
    required this.questionId,
    required this.answer,
  });

  @override
  String toString() => 'SelectAnswer(questionId: $questionId, answer: $answer)';
}

/// Event fired when user presses the Next button
class NextPressed extends PatientEvent {
  NextPressed();

  @override
  String toString() => 'NextPressed()';
}

/// Event fired when user presses the Previous/Back button
class PreviousPressed extends PatientEvent {
  PreviousPressed();

  @override
  String toString() => 'PreviousPressed()';
}
