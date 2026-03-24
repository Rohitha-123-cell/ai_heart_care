import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/patient/patient_bloc.dart';
import '../../bloc/patient/patient_event.dart';
import '../../bloc/patient/patient_state.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/question.dart';
import '../../widgets/custom_button.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final PatientBloc _patientBloc = PatientBloc();

  @override
  void dispose() {
    _patientBloc.close();
    super.dispose();
  }

  void _onAnswerSelected(String questionId, String answer) {
    _patientBloc.add(SelectAnswer(questionId: questionId, answer: answer));
  }

  void _onNextStep() {
    _patientBloc.add(NextPressed());
  }

  void _onPreviousStep() {
    _patientBloc.add(PreviousPressed());
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return BlocProvider.value(
      value: _patientBloc,
      child: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          // Handle Initial State
          if (state is InitialState) {
            return _buildInitialState(context, state, width, height);
          }

          // Handle Answer Updated State
          if (state is AnswerUpdatedState) {
            return _buildAnswerUpdatedState(context, state, width, height);
          }

          // Handle Validation Error State
          if (state is ValidationErrorState) {
            return _buildValidationErrorState(context, state, width, height);
          }

          // Handle Completed State
          if (state is CompletedState) {
            return _buildCompletedState(context, state, width, height);
          }

          // Default loading state
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, InitialState state, double width, double height) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildQuestionnaire(context, state, width, height),
    );
  }

  Widget _buildAnswerUpdatedState(BuildContext context, AnswerUpdatedState state, double width, double height) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildQuestionnaire(context, state, width, height),
    );
  }

  Widget _buildValidationErrorState(BuildContext context, ValidationErrorState state, double width, double height) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
          ),
          _buildQuestionnaire(context, state, width, height),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: GlassCard(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.06),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: height * 0.02),
                        Text(
                          state.errorMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: height * 0.02),
                        CustomButton(
                          text: "OK",
                          onTap: () {
                            // Return to previous state by re-adding InitialState
                            _patientBloc.add(PreviousPressed());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, CompletedState state, double width, double height) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: GlassCard(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.06),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        SizedBox(height: height * 0.03),
                        const Text(
                          "Form Completed!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        Text(
                          "You've answered ${state.answeredCount} questions",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: height * 0.04),
                        CustomButton(
                          text: "Continue",
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaire(BuildContext context, PatientState state, double width, double height) {
    if (state.questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final currentQuestion = state.questions[state.currentStep];
    final totalSteps = state.questions.length;
    final progress = (state.currentStep + 1) / totalSteps;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: width * 0.06),
                  ),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Text(
                    "Patient Information",
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${state.currentStep + 1} of $totalSteps",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.03),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.questionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      ...AnswerOption.allOptions.map((option) {
                        final isSelected = currentQuestion.selectedAnswer == option;
                        return Padding(
                          padding: EdgeInsets.only(bottom: height * 0.015),
                          child: GestureDetector(
                            onTap: () => _onAnswerSelected(currentQuestion.id, option),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(width * 0.04),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(width * 0.03),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.orange
                                      : Colors.white.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.orange : Colors.white70,
                                  ),
                                  SizedBox(width: width * 0.03),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Row(
              children: [
                if (state.canGoPrevious)
                  Expanded(
                    child: GestureDetector(
                      onTap: _onPreviousStep,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(width * 0.03),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Previous",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (state.canGoPrevious) SizedBox(width: width * 0.03),
                Expanded(
                  child: state.answeredCount == state.questions.length
                      ? CustomButton(
                          text: "Submit",
                          onTap: () => Navigator.pop(context, _patientBloc.getAllAnswers()),
                        )
                      : CustomButton(
                          text: state.canGoNext ? "Next" : "Submit",
                          onTap: state.canGoNext ? _onNextStep : _onNextStep,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
