import 'package:equatable/equatable.dart';

enum HeartRateStatus { initial, loading, loaded, error }

class HeartRateState extends Equatable {
  final HeartRateStatus status;
  final double heartRate;
  final double estimatedHeartRate;
  final String heartRateStatus;
  final List<double> heartRateHistory;
  final String? errorMessage;

  const HeartRateState({
    this.status = HeartRateStatus.initial,
    this.heartRate = 72.0,
    this.estimatedHeartRate = 72.0,
    this.heartRateStatus = "Normal",
    this.heartRateHistory = const [],
    this.errorMessage,
  });

  HeartRateState copyWith({
    HeartRateStatus? status,
    double? heartRate,
    double? estimatedHeartRate,
    String? heartRateStatus,
    List<double>? heartRateHistory,
    String? errorMessage,
  }) {
    return HeartRateState(
      status: status ?? this.status,
      heartRate: heartRate ?? this.heartRate,
      estimatedHeartRate: estimatedHeartRate ?? this.estimatedHeartRate,
      heartRateStatus: heartRateStatus ?? this.heartRateStatus,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        heartRate,
        estimatedHeartRate,
        heartRateStatus,
        heartRateHistory,
        errorMessage,
      ];
}
