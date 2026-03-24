import 'package:flutter_bloc/flutter_bloc.dart';
import 'bmi_event.dart';
import 'bmi_state.dart';

class BmiBloc extends Bloc<BmiEvent, BmiState> {
  String _height = '';
  String _weight = '';

  BmiBloc() : super(const BmiInitialState()) {
    on<UpdateHeight>(_onUpdateHeight);
    on<UpdateWeight>(_onUpdateWeight);
    on<CalculateBmi>(_onCalculateBmi);
    on<ResetBmi>(_onResetBmi);
  }

  void _onUpdateHeight(UpdateHeight event, Emitter<BmiState> emit) {
    _height = event.height;
  }

  void _onUpdateWeight(UpdateWeight event, Emitter<BmiState> emit) {
    _weight = event.weight;
  }

  Future<void> _onCalculateBmi(CalculateBmi event, Emitter<BmiState> emit) async {
    // Emit loading state
    emit(const BmiLoadingState());

    // Validate inputs
    if (_height.isEmpty) {
      emit(const BmiErrorState('Please enter your height'));
      return;
    }

    if (_weight.isEmpty) {
      emit(const BmiErrorState('Please enter your weight'));
      return;
    }

    final height = double.tryParse(_height);
    final weight = double.tryParse(_weight);

    if (height == null || height <= 0) {
      emit(const BmiErrorState('Please enter a valid height (greater than 0)'));
      return;
    }

    if (weight == null || weight <= 0) {
      emit(const BmiErrorState('Please enter a valid weight (greater than 0)'));
      return;
    }

    // Add small delay to show loading state (optional, for better UX)
    await Future.delayed(const Duration(milliseconds: 500));

    // Calculate BMI
    // BMI = weight (kg) / height (m)²
    double heightInMeters = height / 100;
    double heightSquared = heightInMeters * heightInMeters;
    double bmi = weight / heightSquared;

    // Round to 2 decimal places
    bmi = double.parse(bmi.toStringAsFixed(2));

    // Determine category
    BmiCategory category;
    String categoryText;

    if (bmi < 18.5) {
      category = BmiCategory.underweight;
      categoryText = 'Underweight';
    } else if (bmi < 25) {
      category = BmiCategory.normal;
      categoryText = 'Normal';
    } else if (bmi < 30) {
      category = BmiCategory.overweight;
      categoryText = 'Overweight';
    } else {
      category = BmiCategory.obese;
      categoryText = 'Obese';
    }

    // Emit calculated state
    emit(BmiCalculatedState(
      bmi: bmi,
      height: height,
      weight: weight,
      category: category,
      categoryText: categoryText,
    ));
  }

  void _onResetBmi(ResetBmi event, Emitter<BmiState> emit) {
    _height = '';
    _weight = '';
    emit(const BmiInitialState());
  }

  /// Helper method to get current BMI value from state
  double? get currentBmi {
    final currentState = state;
    if (currentState is BmiCalculatedState) {
      return currentState.bmi;
    }
    return null;
  }

  /// Helper method to get current category from state
  String? get currentCategory {
    final currentState = state;
    if (currentState is BmiCalculatedState) {
      return currentState.categoryText;
    }
    return null;
  }
}
