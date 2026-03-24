import 'package:equatable/equatable.dart';

/// BMI Category enum for better type safety
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese,
}

abstract class BmiState extends Equatable {
  const BmiState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no data is entered
class BmiInitialState extends BmiState {
  const BmiInitialState();
}

/// Loading state while calculating BMI
class BmiLoadingState extends BmiState {
  const BmiLoadingState();
}

/// State when BMI has been calculated
class BmiCalculatedState extends BmiState {
  final double bmi;
  final double height;
  final double weight;
  final BmiCategory category;
  final String categoryText;

  const BmiCalculatedState({
    required this.bmi,
    required this.height,
    required this.weight,
    required this.category,
    required this.categoryText,
  });

  @override
  List<Object?> get props => [bmi, height, weight, category, categoryText];
}

/// Error state when invalid input is provided
class BmiErrorState extends BmiState {
  final String message;

  const BmiErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
