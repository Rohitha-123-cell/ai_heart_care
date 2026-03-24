class HealthInsight {
  final String userId;
  final String overallStatus; // Excellent, Good, Fair, Poor
  final double healthScore; // 0-100
  final List<String> riskFactors;
  final List<String> recommendations;
  final String aiAnalysis;
  final DateTime generatedAt;

  HealthInsight({
    required this.userId,
    required this.overallStatus,
    required this.healthScore,
    required this.riskFactors,
    required this.recommendations,
    required this.aiAnalysis,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'overall_status': overallStatus,
      'health_score': healthScore,
      'risk_factors': riskFactors.join('|'),
      'recommendations': recommendations.join('|'),
      'ai_analysis': aiAnalysis,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory HealthInsight.fromMap(Map<String, dynamic> map) {
    return HealthInsight(
      userId: map['user_id'] ?? '',
      overallStatus: map['overall_status'] ?? 'Unknown',
      healthScore: map['health_score']?.toDouble() ?? 0.0,
      riskFactors: (map['risk_factors'] as String?)?.split('|') ?? [],
      recommendations: (map['recommendations'] as String?)?.split('|') ?? [],
      aiAnalysis: map['ai_analysis'] ?? '',
      generatedAt: DateTime.tryParse(map['generated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class CombinedHealthData {
  final double bmi;
  final int heartRate;
  final int steps;
  final double sleepHours;
  final double heartRisk;
  final int stressScore;
  final int caloriesBurned;

  CombinedHealthData({
    required this.bmi,
    required this.heartRate,
    required this.steps,
    required this.sleepHours,
    required this.heartRisk,
    required this.stressScore,
    required this.caloriesBurned,
  });

  Map<String, dynamic> toMap() {
    return {
      'bmi': bmi,
      'heart_rate': heartRate,
      'steps': steps,
      'sleep_hours': sleepHours,
      'heart_risk': heartRisk,
      'stress_score': stressScore,
      'calories_burned': caloriesBurned,
    };
  }
}
