import 'package:flutter_bloc/flutter_bloc.dart';
import 'patient_event.dart';
import 'patient_state.dart';
import '../../models/question.dart';
import '../../services/health_data_provider.dart';

/// BLoC for managing patient questionnaire state
class PatientBloc extends Bloc<PatientEvent, PatientState> {
  // Store the predicted heart rate based on answers
  int _predictedHeartRate = 72;
  
  PatientBloc() : super(_createInitialState()) {
    on<SelectAnswer>(_onSelectAnswer);
    on<NextPressed>(_onNextPressed);
    on<PreviousPressed>(_onPreviousPressed);
  }

  /// Get the predicted heart rate
  int get predictedHeartRate => _predictedHeartRate;

  /// Creates the initial state with predefined health questions
  /// Includes both health conditions and daily activity questions
  static PatientState _createInitialState() {
    final questions = [
      // Health condition questions (Yes/No/Don't know)
      Question(
        id: 'q1',
        questionText: "I'm overweight or obese",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q2',
        questionText: "Smoked at least 100 cigarettes in a lifetime",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q3',
        questionText: "I have diabetes",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q4',
        questionText: "I have hypertension",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q5',
        questionText: "I've recently suffered an injury",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q6',
        questionText: "Family history of allergic disease (asthma, dermatitis, food allergy)",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q7',
        questionText: "I'm pregnant",
        customOptions: AnswerOption.allOptions,
      ),
      // Daily activity questions for heart rate prediction
      Question(
        id: 'q8',
        questionText: "How often do you exercise or do physical activities?",
        customOptions: AnswerOption.exerciseOptions,
      ),
      Question(
        id: 'q9',
        questionText: "How would you rate your stress level?",
        customOptions: AnswerOption.stressOptions,
      ),
      Question(
        id: 'q10',
        questionText: "How many hours of sleep do you get daily?",
        customOptions: AnswerOption.sleepOptions,
      ),
      Question(
        id: 'q11',
        questionText: "Do you consume caffeine or energy drinks daily?",
        customOptions: AnswerOption.allOptions,
      ),
      Question(
        id: 'q12',
        questionText: "Do you smoke or use tobacco products?",
        customOptions: AnswerOption.allOptions,
      ),
    ];

    return InitialState(questions: questions);
  }


  /// Analyze answers and predict heart rate based on health factors and daily activities
  int _analyzeAnswersToPredictHeartRate(List<Question> questions) {
    int baseHeartRate = 72; // Average resting heart rate
    int adjustments = 0;
    
    // Analyze health condition answers
    for (final question in questions) {
      final answer = question.selectedAnswer;
      
      switch (question.id) {
        // Health conditions
        case 'q1': // Overweight/obese
          if (answer == AnswerOption.yes) {
            adjustments += 8; // Higher heart rate due to extra weight
          } else if (answer == AnswerOption.dontKnow) {
            adjustments += 3;
          }
          break;
        case 'q2': // Smoked 100 cigarettes
          if (answer == AnswerOption.yes) {
            adjustments += 10; // Smoking affects heart rate
          }
          break;
        case 'q3': // Diabetes
          if (answer == AnswerOption.yes) {
            adjustments += 6;
          }
          break;
        case 'q4': // Hypertension
          if (answer == AnswerOption.yes) {
            adjustments += 8;
          }
          break;
        case 'q5': // Recent injury
          if (answer == AnswerOption.yes) {
            adjustments += 5; // Pain can increase heart rate
          }
          break;
        case 'q6': // Family history of allergic disease
          if (answer == AnswerOption.yes) {
            adjustments += 2;
          }
          break;
        case 'q7': // Pregnant
          if (answer == AnswerOption.yes) {
            adjustments += 15; // Pregnancy increases heart rate
          }
          break;
        
        // Daily activity questions
        case 'q8': // Exercise frequency
          if (answer == 'Rarely' || answer == "Don't know") {
            adjustments += 8; // Sedentary lifestyle
          } else if (answer == 'Occasionally') {
            adjustments += 2;
          } else if (answer == 'Regularly') {
            adjustments -= 5; // Athletes have lower resting HR
          } else if (answer == 'Daily') {
            adjustments -= 8;
          }
          break;
        case 'q9': // Stress level
          if (answer == 'High' || answer == 'Very High') {
            adjustments += 15;
          } else if (answer == 'Moderate') {
            adjustments += 5;
          } else if (answer == 'Low') {
            adjustments -= 3;
          } else if (answer == 'Very Low') {
            adjustments -= 5;
          }
          break;
        case 'q10': // Sleep hours
          if (answer == 'Less than 5 hours') {
            adjustments += 10;
          } else if (answer == '5-6 hours') {
            adjustments += 5;
          } else if (answer == '7-8 hours') {
            adjustments += 0;
          } else if (answer == 'More than 8 hours') {
            adjustments += 2;
          }
          break;
        case 'q11': // Caffeine/energy drinks
          if (answer == AnswerOption.yes) {
            adjustments += 8;
          } else if (answer == AnswerOption.dontKnow) {
            adjustments += 3;
          }
          break;
        case 'q12': // Smoke/tobacco
          if (answer == AnswerOption.yes) {
            adjustments += 12;
          }
          break;
      }
    }
    
    // Calculate final heart rate
    int predictedHR = baseHeartRate + adjustments;
    
    // Clamp to reasonable range (40-140 BPM)
    return predictedHR.clamp(40, 140);
  }

  /// Get heart rate status based on predicted value
  String _getHeartRateStatus(int bpm) {
    if (bpm < 60) return "Low (Bradycardia)";
    if (bpm < 80) return "Normal";
    if (bpm < 100) return "Elevated";
    return "High (Tachycardia)";
  }

  /// Get recommendation based on predicted heart rate
  String _getHeartRateRecommendation(int bpm) {
    if (bpm < 60) {
      return "Your predicted resting heart rate is low. Regular exercise may help increase it. Consult a doctor if you feel dizzy.";
    } else if (bpm < 80) {
      return "Your predicted heart rate is in the healthy range! Keep maintaining a healthy lifestyle.";
    } else if (bpm < 100) {
      return "Your predicted heart rate is slightly elevated. Consider stress management and regular exercise.";
    } else {
      return "Your predicted heart rate is high. We recommend reducing stress, limiting caffeine, and consulting a healthcare provider.";
    }
  }

  /// Handles answer selection
  void _onSelectAnswer(SelectAnswer event, Emitter<PatientState> emit) {
    // Find the question and update its answer
    final updatedQuestions = state.questions.map((q) {
      if (q.id == event.questionId) {
        return q.copyWith(selectedAnswer: event.answer);
      }
      return q;
    }).toList();

    // Count how many questions have answers
    final answeredCount = updatedQuestions.where((q) => q.selectedAnswer != null).length;

    emit(AnswerUpdatedState(
      questions: updatedQuestions,
      currentStep: state.currentStep,
      answeredCount: answeredCount,
      questionId: event.questionId,
      answer: event.answer,
    ));
  }

  /// Handles next button press
  void _onNextPressed(NextPressed event, Emitter<PatientState> emit) {
    // Prevent multiple clicks by checking if already submitted
    if (state is CompletedState) return;
    
    // Get the latest questions from state
    final questions = state.questions;
    
    // Check if ALL questions are answered
    final totalAnswered = questions.where((q) => q.selectedAnswer != null).length;
    
    if (totalAnswered == questions.length) {
      // Calculate predicted heart rate based on all answers
      _predictedHeartRate = _analyzeAnswersToPredictHeartRate(questions);
      
      // All questions answered - emit completed state on first click
      emit(CompletedState(
        questions: questions,
        answeredCount: totalAnswered,
      ));
      return;
    }
    
    // If not all answered, check current question
    final currentQuestion = questions[state.currentStep];
    
    if (currentQuestion.selectedAnswer == null) {
      emit(ValidationErrorState(
        questions: questions,
        currentStep: state.currentStep,
        answeredCount: totalAnswered,
        errorMessage: 'Please answer all questions before submitting',
      ));
      return;
    }
    
    // Move to next question if not all answered
    if (state.canGoNext) {
      emit(InitialState(
        questions: questions,
        currentStep: state.currentStep + 1,
        answeredCount: totalAnswered,
      ));
    }
  }

  /// Handles previous button press
  void _onPreviousPressed(PreviousPressed event, Emitter<PatientState> emit) {
    if (state.canGoPrevious) {
      emit(InitialState(
        questions: state.questions,
        currentStep: state.currentStep - 1,
        answeredCount: state.answeredCount,
      ));
    }
  }

  /// Get all answers as a map (useful for saving/submission)
  Map<String, String?> getAllAnswers() {
    final answers = <String, String?>{};
    for (final question in state.questions) {
      answers[question.id] = question.selectedAnswer;
    }
    return answers;
  }
}
