import 'package:flutter_bloc/flutter_bloc.dart';
import 'heart_rate_event.dart';
import 'heart_rate_state.dart';

class HeartRateBloc extends Bloc<HeartRateEvent, HeartRateState> {
  HeartRateBloc() : super(const HeartRateState()) {
    on<HeartRateMeasureRequested>(_onMeasureRequested);
    on<HeartRateLoadHistory>(_onLoadHistory);
    on<HeartRateUpdateData>(_onUpdateData);
    on<HeartRateReset>(_onReset);
  }

  Future<void> _onMeasureRequested(
    HeartRateMeasureRequested event,
    Emitter<HeartRateState> emit,
  ) async {
    emit(state.copyWith(status: HeartRateStatus.loading));
    
    // Simulate measurement delay
    await Future.delayed(const Duration(seconds: 2));
    
    emit(state.copyWith(
      status: HeartRateStatus.loaded,
      heartRate: state.estimatedHeartRate,
    ));
  }

  Future<void> _onLoadHistory(
    HeartRateLoadHistory event,
    Emitter<HeartRateState> emit,
  ) async {
    emit(state.copyWith(status: HeartRateStatus.loading));
    
    try {
      // Load history from storage or generate sample data
      final history = List.generate(
        event.limit,
        (i) => 70.0 + (i % 10) - 5,
      );
      
      emit(state.copyWith(
        status: HeartRateStatus.loaded,
        heartRateHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HeartRateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onUpdateData(
    HeartRateUpdateData event,
    Emitter<HeartRateState> emit,
  ) {
    // Calculate estimated heart rate based on health data
    double baseHR = 72.0;
    
    // Age adjustment
    if (event.age < 20) {
      baseHR -= 5;
    } else if (event.age > 50) {
      baseHR += (event.age - 50) * 0.3;
    }
    
    // BMI adjustment
    if (event.bmi > 30) {
      baseHR += 8;
    } else if (event.bmi > 25) {
      baseHR += 4;
    } else if (event.bmi < 18.5) {
      baseHR -= 3;
    }
    
    // Sleep adjustment
    if (event.sleepHours < 6) {
      baseHR += 5;
    } else if (event.sleepHours > 9) {
      baseHR -= 2;
    }
    
    // Activity adjustment
    if (event.steps > 10000) {
      baseHR -= 5;
    } else if (event.steps < 5000) {
      baseHR += 3;
    }
    
    final estimatedHeartRate = baseHR.clamp(50.0, 110.0);
    
    String status;
    if (estimatedHeartRate < 60) {
      status = "Low (Athletic)";
    } else if (estimatedHeartRate < 80) {
      status = "Normal";
    } else if (estimatedHeartRate < 100) {
      status = "Elevated";
    } else {
      status = "High";
    }
    
    emit(state.copyWith(
      estimatedHeartRate: estimatedHeartRate,
      heartRate: event.heartRate != 0 ? event.heartRate : estimatedHeartRate,
      heartRateStatus: status,
    ));
  }

  void _onReset(
    HeartRateReset event,
    Emitter<HeartRateState> emit,
  ) {
    emit(const HeartRateState());
  }
}
