import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';
import 'health_data_event.dart';
import 'health_data_state.dart';

class HealthDataBloc extends Bloc<HealthDataEvent, HealthDataState> {
  final SupabaseClient _client;

  HealthDataBloc({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const HealthDataState()) {
    on<HealthDataLoadRequested>(_onLoadRequested);
    on<HealthDataSaveRequested>(_onSaveRequested);
    on<HealthDataUpdateRequested>(_onUpdateRequested);
    on<HealthDataCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoadRequested(
    HealthDataLoadRequested event,
    Emitter<HealthDataState> emit,
  ) async {
    emit(state.copyWith(status: HealthDataStatus.loading));

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(state.copyWith(
          status: HealthDataStatus.error,
          errorMessage: 'User not logged in',
        ));
        return;
      }

      // Try to load from Supabase
      final response = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        emit(state.copyWith(
          status: HealthDataStatus.loaded,
          bmi: (data['bmi'] ?? 24.0).toDouble(),
          heartRate: (data['heart_rate'] ?? 72.0).toDouble(),
          weight: (data['weight'] ?? 70.0).toDouble(),
          sleepHours: (data['sleep_hours'] ?? 7.0).toDouble(),
          steps: data['steps'] ?? 8000,
          hasHealthData: true,
        ));
      } else {
        emit(state.copyWith(
          status: HealthDataStatus.loaded,
          hasHealthData: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: HealthDataStatus.loaded,
        hasHealthData: false,
      ));
    }
  }

  Future<void> _onSaveRequested(
    HealthDataSaveRequested event,
    Emitter<HealthDataState> emit,
  ) async {
    emit(state.copyWith(status: HealthDataStatus.saving));

    try {
      // Save to Supabase
      await StorageService.saveHealthMetrics(
        bmi: event.bmi,
        heartRate: event.heartRate,
        bloodPressure: 120, // Default value
        weight: event.weight,
        sleepHours: event.sleepHours,
        steps: event.steps,
      );

      // Save risk score
      await StorageService.saveRiskScore(
        riskType: 'heart',
        score: event.heartRisk,
        level: event.heartRisk < 20
            ? 'Low'
            : event.heartRisk < 40
                ? 'Moderate'
                : 'High',
      );

      emit(state.copyWith(
        status: HealthDataStatus.saved,
        bmi: event.bmi,
        heartRisk: event.heartRisk,
        sleepHours: event.sleepHours,
        steps: event.steps,
        heartRate: event.heartRate,
        weight: event.weight,
        height: event.height,
        age: event.age,
        bmiCategory: event.bmiCategory,
        hasHealthData: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HealthDataStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onUpdateRequested(
    HealthDataUpdateRequested event,
    Emitter<HealthDataState> emit,
  ) {
    emit(state.copyWith(
      status: HealthDataStatus.loaded,
      bmi: event.bmi ?? state.bmi,
      age: event.age ?? state.age,
      steps: event.steps ?? state.steps,
      sleepHours: event.sleepHours ?? state.sleepHours,
      heartRisk: event.heartRisk ?? state.heartRisk,
      heartRate: event.heartRate ?? state.heartRate,
      weight: event.weight ?? state.weight,
      height: event.height ?? state.height,
      stressScore: event.stressScore ?? state.stressScore,
      bmiCategory: event.bmiCategory ?? state.bmiCategory,
    ));
  }

  Future<void> _onCheckRequested(
    HealthDataCheckRequested event,
    Emitter<HealthDataState> emit,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(state.copyWith(hasHealthData: false));
        return;
      }

      final response = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', user.id)
          .limit(1);

      emit(state.copyWith(hasHealthData: response.isNotEmpty));
    } catch (e) {
      emit(state.copyWith(hasHealthData: false));
    }
  }
}
