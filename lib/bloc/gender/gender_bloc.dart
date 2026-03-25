import 'package:flutter_bloc/flutter_bloc.dart';
import 'gender_event.dart';
import 'gender_state.dart';
import '../../models/gender.dart';

/// BLoC for managing gender selection state
class GenderBloc extends Bloc<GenderEvent, GenderState> {
  GenderBloc() : super(const GenderInitialState()) {
    on<SelectGender>(_onSelectGender);
    on<GenderNextPressed>(_onNextPressed);
    on<GenderBackPressed>(_onBackPressed);
  }

  /// Handles gender selection
  void _onSelectGender(SelectGender event, Emitter<GenderState> emit) {
    emit(GenderSelectedState(selectedGender: event.gender));
  }

  /// Handles next button press
  void _onNextPressed(GenderNextPressed event, Emitter<GenderState> emit) {
    final selectedGender = state.selectedGender;
    if (selectedGender == null) {
      emit(const GenderValidationErrorState(
        errorMessage: 'Please select an option',
      ));
      return;
    }

    emit(GenderNavigationState(
      gender: selectedGender,
      destination: 'patient',
    ));
  }

  /// Handles back button press
  void _onBackPressed(GenderBackPressed event, Emitter<GenderState> emit) {
    final selectedGender = state.selectedGender;
    if (selectedGender == null) {
      emit(const GenderInitialState());
      return;
    }

    emit(GenderNavigationState(
      gender: selectedGender,
      destination: 'health_input',
    ));
  }
}
