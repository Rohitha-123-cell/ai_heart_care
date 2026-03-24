import 'package:equatable/equatable.dart';

abstract class HeartRateEvent extends Equatable {
  const HeartRateEvent();

  @override
  List<Object?> get props => [];
}

class HeartRateMeasureRequested extends HeartRateEvent {
  const HeartRateMeasureRequested();
}

class HeartRateLoadHistory extends HeartRateEvent {
  final int limit;

  const HeartRateLoadHistory({this.limit = 30});

  @override
  List<Object?> get props => [limit];
}

class HeartRateUpdateData extends HeartRateEvent {
  final double heartRate;
  final double bmi;
  final int age;
  final int steps;
  final double sleepHours;

  const HeartRateUpdateData({
    required this.heartRate,
    required this.bmi,
    required this.age,
    required this.steps,
    required this.sleepHours,
  });

  @override
  List<Object?> get props => [heartRate, bmi, age, steps, sleepHours];
}

class HeartRateReset extends HeartRateEvent {
  const HeartRateReset();
}
