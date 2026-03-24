import 'package:flutter/foundation.dart';
import '../../models/question.dart';

/// Base class for all Patient BLoC states
@immutable
abstract class PatientState {
  /// List of all questions in the questionnaire
  final List<Question> questions;
  
  /// Current step index (0-based)
  final int currentStep;
  
  /// Number of answered questions
  final int answeredCount;

  const PatientState({
    required this.questions,
    required this.currentStep,
    required this.answeredCount,
  });

  /// Calculate progress as a value between 0.0 and 1.0
  double get progress {
    if (questions.isEmpty) return 0.0;
    return answeredCount / questions.length;
  }

  /// Check if all questions are answered
  bool get isCompleted => answeredCount == questions.length;

  /// Check if user can go to next step
  bool get canGoNext => currentStep < questions.length - 1;

  /// Check if user can go to previous step
  bool get canGoPrevious => currentStep > 0;
}

/// Initial state when the questionnaire starts
class InitialState extends PatientState {
  const InitialState({
    required super.questions,
    super.currentStep = 0,
    super.answeredCount = 0,
  });

  @override
  String toString() => 'InitialState(currentStep: $currentStep, answeredCount: $answeredCount)';
}

/// State after an answer is updated
class AnswerUpdatedState extends PatientState {
  final String questionId;
  final String answer;

  const AnswerUpdatedState({
    required super.questions,
    required super.currentStep,
    required super.answeredCount,
    required this.questionId,
    required this.answer,
  });

  @override
  String toString() => 'AnswerUpdatedState(questionId: $questionId, answer: $answer)';
}

/// State when validation fails (e.g., trying to proceed without answering)
class ValidationErrorState extends PatientState {
  final String errorMessage;

  const ValidationErrorState({
    required super.questions,
    required super.currentStep,
    required super.answeredCount,
    required this.errorMessage,
  });

  @override
  String toString() => 'ValidationErrorState(error: $errorMessage)';
}

/// State when all questions are answered and form is completed
class CompletedState extends PatientState {
  const CompletedState({
    required super.questions,
    required super.answeredCount,
  }) : super(currentStep: 0);

  @override
  String toString() => 'CompletedState(answeredCount: $answeredCount)';
}
