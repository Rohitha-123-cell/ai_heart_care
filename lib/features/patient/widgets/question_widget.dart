import 'package:flutter/material.dart';
import '../../../models/question.dart';
import 'radio_option_widget.dart';

/// Reusable widget for displaying a single question with its options
class QuestionWidget extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final ValueChanged<String> onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswerSelected,
  });

  // Primary blue color for the medical app theme
  static const Color _primaryColor = Color(0xFF2F80ED);

  /// Show info dialog when info icon is tapped
  void _showInfoDialog(BuildContext context, String questionText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: _primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Question Info'),
          ],
        ),
        content: Text(
          _getInfoText(questionText),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Get contextual info for each question
  String _getInfoText(String questionText) {
    final Map<String, String> infoMap = {
      "I'm overweight or obese": 
          "Body Mass Index (BMI) of 25 or higher indicates overweight, "
          "while BMI of 30 or higher indicates obesity. This is calculated "
          "using your height and weight.",
      "Smoked at least 100 cigarettes in a lifetime":
          "This is a standard measure used to define 'ever smokers' in medical research. "
          "Even if you've quit, this information helps assess long-term health risks.",
      "I have diabetes":
          "Diabetes is a chronic condition where blood sugar levels are too high. "
          "Common types include Type 1, Type 2, and gestational diabetes.",
      "I have hypertension":
          "Hypertension (high blood pressure) is defined as blood pressure readings "
          "of 130/80 mmHg or higher. It often has no symptoms but increases risk of "
          "heart disease and stroke.",
      "I've recently suffered an injury":
          "Recent injuries may affect your current health assessment and treatment options. "
          "Please describe the nature and severity of the injury.",
      "Family history of allergic disease (asthma, dermatitis, food allergy)":
          "A family history of allergic conditions can indicate genetic predisposition "
          "to allergies. This helps in preventive care and treatment planning.",
      "I'm pregnant":
          "Pregnancy affects various health considerations including medication safety, "
          "imaging recommendations, and certain health risk assessments.",
    };
    return infoMap[questionText] ?? "This question helps us understand your health background better.";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with number and info button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$questionNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Question text
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e),
                      height: 1.3,
                    ),
                  ),
                ),
                // Info icon button
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: _primaryColor.withOpacity(0.8),
                    size: 22,
                  ),
                  onPressed: () => _showInfoDialog(context, question.questionText),
                  tooltip: 'More information',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Answer options - use custom options if available, otherwise use default Yes/No/Don't know
            ...(question.customOptions ?? AnswerOption.allOptions).map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioOptionWidget(
                  option: option,
                  selectedAnswer: question.selectedAnswer,
                  onChanged: onAnswerSelected,
                ),
              );
            }),

          ],
        ),
      ),
    );
  }
}
