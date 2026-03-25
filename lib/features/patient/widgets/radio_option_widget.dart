import 'package:flutter/material.dart';

/// Reusable widget for displaying a radio option in the patient questionnaire
class RadioOptionWidget extends StatelessWidget {
  final String option;
  final String? selectedAnswer;
  final ValueChanged<String> onChanged;

  const RadioOptionWidget({
    super.key,
    required this.option,
    required this.selectedAnswer,
    required this.onChanged,
  });

  // Primary blue color for the medical app theme
  static const Color _primaryColor = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedAnswer == option;

    return InkWell(
      onTap: () => onChanged(option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom radio button
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? _primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primaryColor : Colors.grey.shade800,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
