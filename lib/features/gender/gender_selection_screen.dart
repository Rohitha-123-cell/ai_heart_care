import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/gender/gender_bloc.dart';
import '../../bloc/gender/gender_event.dart';
import '../../bloc/gender/gender_state.dart';
import '../../models/gender.dart';
import '../health_input/health_input_screen.dart';
import '../patient/patient_screen.dart';

/// Gender selection screen with two large selectable cards
class GenderSelectionScreen extends StatelessWidget {
  const GenderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GenderBloc(),
      child: const _GenderSelectionContent(),
    );
  }
}

class _GenderSelectionContent extends StatelessWidget {
  const _GenderSelectionContent();

  // Primary blue color for the medical app theme
  static const Color _primaryColor = Color(0xFF2F80ED);
  static const Color _successColor = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenderBloc, GenderState>(
      listener: (context, state) {
        // Show validation error as snackbar
        if (state is GenderValidationErrorState) {
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

        // Handle navigation
        if (state is GenderNavigationState) {
          if (state.destination == 'patient') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PatientScreen()),
            );
          } else if (state.destination == 'health_input') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HealthInputScreen()),
            );
          }
        }
      },
      builder: (context, state) {
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
              onPressed: () {
                context.read<GenderBloc>().add(GenderBackPressed());
              },
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Question text
                  const Text(
                    "What is your sex?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Info section
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "What should I select?",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Gender selection cards - Made scrollable to prevent overflow
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Female card
                          _GenderCard(
                            gender: Gender.female,
                            isSelected: state.selectedGender == Gender.female,
                            onTap: () {
                              context.read<GenderBloc>().add(
                                SelectGender(gender: Gender.female),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Male card
                          _GenderCard(
                            gender: Gender.male,
                            isSelected: state.selectedGender == Gender.male,
                            onTap: () {
                              context.read<GenderBloc>().add(
                                SelectGender(gender: Gender.male),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Report issue text
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Show report dialog or navigate to report page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report feature coming soon'),
                          ),
                        );
                      },
                      child: Text(
                        'Report an issue with this question',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Next button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<GenderBloc>().add(GenderNextPressed());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gender selection card widget
class _GenderCard extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gender icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                gender == Gender.female ? Icons.female : Icons.male,
                color: isSelected ? _primaryColor : Colors.grey.shade600,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            // Gender text
            Expanded(
              child: Text(
                gender.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? _primaryColor : Colors.grey.shade800,
                ),
              ),
            ),
            // Selection indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
