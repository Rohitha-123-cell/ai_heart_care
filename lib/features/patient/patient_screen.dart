import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/patient/patient_bloc.dart';
import '../../bloc/patient/patient_event.dart';
import '../../bloc/patient/patient_state.dart';
import '../../models/question.dart';
import '../../services/health_data_provider.dart';
import '../../core/utils/responsive.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/question_widget.dart';


/// Patient questionnaire screen with health-related questions
/// This screen displays a list of questions with Yes/No/Don't know options
class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientBloc(),
      child: const _PatientScreenContent(),
    );
  }
}

class _PatientScreenContent extends StatelessWidget {
  const _PatientScreenContent();

  // Primary blue color for the medical app theme
  static const Color _primaryColor = Color(0xFF2F80ED);
  static const Color _successColor = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light grey background
      appBar: AppBar(
        title: const Text(
          'Patient',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<PatientBloc, PatientState>(
        listener: (context, state) {
          // Show validation error as snackbar
          if (state is ValidationErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          
          // Handle completion - show completion dialog
          if (state is CompletedState) {
            // Get the bloc and calculate predicted heart rate
            final bloc = context.read<PatientBloc>();
            final predictedHR = bloc.predictedHeartRate;
            
            // Update the health data provider with predicted heart rate
            healthDataProvider.setHealthData(heartRate: predictedHR.toDouble());
            
            _showCompletionDialog(context, state, predictedHR);
          }

        },
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
                children: [
              // Progress indicator section
              _buildProgressSection(state),
              
              // Scrollable list of questions
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: state.questions.length,
                  itemBuilder: (context, index) {
                    final question = state.questions[index];
                    return Column(
                      children: [
                        QuestionWidget(
                          question: question,
                          questionNumber: index + 1,
                          totalQuestions: state.questions.length,
                          onAnswerSelected: (answer) {
                            context.read<PatientBloc>().add(
                              SelectAnswer(
                                questionId: question.id,
                                answer: answer,
                              ),
                            );
                          },
                        ),
                        // Subtle divider between questions
                        if (index < state.questions.length - 1)
                          Divider(
                            height: 1,
                            indent: 32,
                            endIndent: 32,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    );
                  },
                ),
              ),
                ],
              ),
            ),
          );
        },
      ),
      // Bottom navigation buttons
      bottomNavigationBar: BlocBuilder<PatientBloc, PatientState>(
        builder: (context, state) {
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = Responsive.maxContentWidth(context);
                final contentWidth = constraints.maxWidth < maxWidth
                    ? constraints.maxWidth
                    : maxWidth;
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: contentWidth,
                    child: Row(
                      children: [
                // Back button
                if (state.canGoPrevious)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<PatientBloc>().add(PreviousPressed());
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 16),
                // Next/Submit button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: state is CompletedState
                        ? null // Disable button after submission
                        : () {
                            context.read<PatientBloc>().add(NextPressed());
                          },
                    icon: state is CompletedState
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            state.answeredCount == state.questions.length
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                    label: Text(
                      state is CompletedState
                          ? 'Submitting...'
                          : (state.answeredCount == state.questions.length
                              ? 'Submit'
                              : 'Next'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state is CompletedState
                          ? _successColor.withOpacity(0.7)
                          : _successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    ),
                  ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Build the progress section showing answered questions count
  Widget _buildProgressSection(PatientState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.progress == 1.0 ? _successColor : _primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.answeredCount} of ${state.questions.length} questions answered',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show completion dialog when all questions are answered
  void _showCompletionDialog(BuildContext context, CompletedState state, int predictedHeartRate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: _successColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Assessment Complete!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your responses have been recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                // Predicted Heart Rate Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.1),
                        _primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Predicted Heart Rate',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '$predictedHeartRate BPM',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Summary of answers
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Responses:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.questions.take(6).map((q) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: _successColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  q.questionText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ': ${q.selectedAnswer}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (state.questions.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${state.questions.length - 6} more answers',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue to Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



