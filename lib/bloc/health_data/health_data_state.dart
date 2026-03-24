import 'package:equatable/equatable.dart';

enum HealthDataStatus { initial, loading, loaded, saving, saved, error }

class HealthDataState extends Equatable {
  final HealthDataStatus status;
  final double bmi;
  final int age;
  final int steps;
  final double sleepHours;
  final double heartRisk;
  final double heartRate;
  final double weight;
  final double height;
  final int stressScore;
  final String bmiCategory;
  final bool hasHealthData;
  final String? errorMessage;

  const HealthDataState({
    this.status = HealthDataStatus.initial,
    this.bmi = 24.0,
    this.age = 30,
    this.steps = 8000,
    this.sleepHours = 7.0,
    this.heartRisk = 25.0,
    this.heartRate = 72.0,
    this.weight = 70.0,
    this.height = 170.0,
    this.stressScore = 35,
    this.bmiCategory = "Normal",
    this.hasHealthData = false,
    this.errorMessage,
  });

  HealthDataState copyWith({
    HealthDataStatus? status,
    double? bmi,
    int? age,
    int? steps,
    double? sleepHours,
    double? heartRisk,
    double? heartRate,
    double? weight,
    double? height,
    int? stressScore,
    String? bmiCategory,
    bool? hasHealthData,
    String? errorMessage,
  }) {
    return HealthDataState(
      status: status ?? this.status,
      bmi: bmi ?? this.bmi,
      age: age ?? this.age,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      heartRisk: heartRisk ?? this.heartRisk,
      heartRate: heartRate ?? this.heartRate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      stressScore: stressScore ?? this.stressScore,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      hasHealthData: hasHealthData ?? this.hasHealthData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bmi,
        age,
        steps,
        sleepHours,
        heartRisk,
        heartRate,
        weight,
        height,
        stressScore,
        bmiCategory,
        hasHealthData,
        errorMessage,
      ];
}
