import 'package:equatable/equatable.dart';

abstract class BmiEvent extends Equatable {
  const BmiEvent();

  @override
  List<Object?> get props => [];
}

/// Update the height value
class UpdateHeight extends BmiEvent {
  final String height;

  const UpdateHeight(this.height);

  @override
  List<Object?> get props => [height];
}

/// Update the weight value
class UpdateWeight extends BmiEvent {
  final String weight;

  const UpdateWeight(this.weight);

  @override
  List<Object?> get props => [weight];
}

/// Calculate BMI when button is pressed
class CalculateBmi extends BmiEvent {
  const CalculateBmi();
}

/// Reset BMI to initial state
class ResetBmi extends BmiEvent {
  const ResetBmi();
}
