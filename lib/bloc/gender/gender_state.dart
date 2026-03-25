import 'package:flutter/foundation.dart';
import '../../models/gender.dart';

/// Base class for all Gender BLoC states
@immutable
abstract class GenderState {
  final Gender? selectedGender;

  const GenderState({this.selectedGender});
}

/// Initial state when the gender selection starts
class GenderInitialState extends GenderState {
  const GenderInitialState({super.selectedGender});
}

/// State after a gender is selected
class GenderSelectedState extends GenderState {
  const GenderSelectedState({required super.selectedGender});
}

/// State when validation fails (trying to proceed without selecting)
class GenderValidationErrorState extends GenderState {
  final String errorMessage;

  const GenderValidationErrorState({
    super.selectedGender,
    required this.errorMessage,
  });

  @override
  String toString() => 'GenderValidationErrorState(error: $errorMessage)';
}

/// State when navigation should occur
class GenderNavigationState extends GenderState {
  final Gender gender;
  final String destination;

  const GenderNavigationState({
    required this.gender,
    required this.destination,
  }) : super(selectedGender: gender);

  @override
  String toString() => 'GenderNavigationState(destination: $destination)';
}
