import 'package:equatable/equatable.dart';

abstract class HealthDataEvent extends Equatable {
  const HealthDataEvent();

  @override
  List<Object?> get props => [];
}

class HealthDataLoadRequested extends HealthDataEvent {
  const HealthDataLoadRequested();
}

class HealthDataSaveRequested extends HealthDataEvent {
  final double bmi;
  final double heartRisk;
  final double sleepHours;
  final int steps;
  final double heartRate;
  final double weight;
  final double height;
  final int age;
  final String bmiCategory;

  const HealthDataSaveRequested({
    required this.bmi,
    required this.heartRisk,
    required this.sleepHours,
    required this.steps,
    required this.heartRate,
    required this.weight,
    required this.height,
    required this.age,
    required this.bmiCategory,
  });

  @override
  List<Object?> get props => [
        bmi,
        heartRisk,
        sleepHours,
        steps,
        heartRate,
        weight,
        height,
        age,
        bmiCategory,
      ];
}

class HealthDataUpdateRequested extends HealthDataEvent {
  final double? bmi;
  final int? age;
  final int? steps;
  final double? sleepHours;
  final double? heartRisk;
  final double? heartRate;
  final double? weight;
  final double? height;
  final int? stressScore;
  final String? bmiCategory;

  const HealthDataUpdateRequested({
    this.bmi,
    this.age,
    this.steps,
    this.sleepHours,
    this.heartRisk,
    this.heartRate,
    this.weight,
    this.height,
    this.stressScore,
    this.bmiCategory,
  });

  @override
  List<Object?> get props => [
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
      ];
}

class HealthDataCheckRequested extends HealthDataEvent {
  const HealthDataCheckRequested();
}
