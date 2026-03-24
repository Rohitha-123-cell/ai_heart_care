/// Question model representing a health-related question
/// Used in the patient screening questionnaire
class Question {
  final String id;
  final String questionText;
  String? selectedAnswer;
  /// Custom answer options for this question (null means use default Yes/No/Don't know)
  final List<String>? customOptions;

  Question({
    required this.id,
    required this.questionText,
    this.selectedAnswer,
    this.customOptions,
  });

  /// Creates a copy of the question with updated answer
  Question copyWith({
    String? id,
    String? questionText,
    String? selectedAnswer,
    List<String>? customOptions,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      customOptions: customOptions ?? this.customOptions,
    );
  }
}

/// Answer options for the patient questionnaire
class AnswerOption {
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String dontKnow = "Don't know";

  /// List of all available answer options for Yes/No questions
  static List<String> get allOptions => [yes, no, dontKnow];
  
  /// Exercise frequency options
  static List<String> get exerciseOptions => [
    'Rarely',
    'Occasionally', 
    'Regularly',
    'Daily',
  ];
  
  /// Stress level options
  static List<String> get stressOptions => [
    'Very Low',
    'Low',
    'Moderate',
    'High',
    'Very High',
  ];
  
  /// Sleep hours options
  static List<String> get sleepOptions => [
    'Less than 5 hours',
    '5-6 hours',
    '7-8 hours',
    'More than 8 hours',
  ];
}


