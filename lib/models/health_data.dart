class HealthData {
  final String userId;
  final double bmi;
  final double heartRisk;
  final double sleepHours;
  final int steps;
  final DateTime date;
  
  HealthData({
    required this.userId,
    required this.bmi,
    required this.heartRisk,
    required this.sleepHours,
    required this.steps,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'bmi': bmi,
      'heart_risk': heartRisk,
      'sleep_hours': sleepHours,
      'steps': steps,
      'date': date.toIso8601String(),
    };
  }
  
  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      userId: map['user_id'],
      bmi: map['bmi']?.toDouble() ?? 0.0,
      heartRisk: map['heart_risk']?.toDouble() ?? 0.0,
      sleepHours: map['sleep_hours']?.toDouble() ?? 0.0,
      steps: map['steps']?.toInt() ?? 0,
      date: DateTime.parse(map['date']),
    );
  }
}