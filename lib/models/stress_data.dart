class StressData {
  final String userId;
  final int heartRate;
  final int activityLevel; // 0-100 scale (sedentary to very active)
  final String stressLevel; // Low, Moderate, High, Very High
  final double stressScore; // 0-100
  final List<String> suggestions;
  final DateTime timestamp;

  StressData({
    required this.userId,
    required this.heartRate,
    required this.activityLevel,
    required this.stressLevel,
    required this.stressScore,
    required this.suggestions,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'heart_rate': heartRate,
      'activity_level': activityLevel,
      'stress_level': stressLevel,
      'stress_score': stressScore,
      'suggestions': suggestions.join(','),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StressData.fromMap(Map<String, dynamic> map) {
    return StressData(
      userId: map['user_id'] ?? '',
      heartRate: map['heart_rate']?.toInt() ?? 0,
      activityLevel: map['activity_level']?.toInt() ?? 0,
      stressLevel: map['stress_level'] ?? 'Unknown',
      stressScore: map['stress_score']?.toDouble() ?? 0.0,
      suggestions: (map['suggestions'] as String?)?.split(',') ?? [],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class StressCategory {
  static const String low = 'Low Stress';
  static const String moderate = 'Moderate Stress';
  static const String high = 'High Stress';
  static const String veryHigh = 'Very High Stress';
}
