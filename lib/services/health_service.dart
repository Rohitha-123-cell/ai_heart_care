import 'dart:math' as math;
import '../models/health_data.dart';

class HealthService {
  // Singleton pattern
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // Current health data
  HealthData? _currentHealthData;

  /// Get current health data
  HealthData? get currentHealthData => _currentHealthData;

  /// Calculate BMI
  static double calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get BMI color
  static int getBMIColor(double bmi) {
    if (bmi < 18.5) return 0xFF2196F3; // Blue
    if (bmi < 25) return 0xFF4CAF50; // Green
    if (bmi < 30) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Calculate heart risk (0-100)
  static double calculateHeartRisk({
    required int age,
    required double bmi,
    required double sleepHours,
    required int steps,
    int? bloodPressureSystolic,
  }) {
    double risk = 0;

    // Age factor (Framingham-based)
    if (age >= 18 && age < 30) {
      risk += age * 0.1;
    } else if (age >= 30 && age < 45) {
      risk += 3.0 + (age - 30) * 0.3;
    } else if (age >= 45 && age < 60) {
      risk += 7.5 + (age - 45) * 0.6;
    } else if (age >= 60) {
      risk += 16.5 + (age - 60) * 0.8;
    }

    // BMI factor
    if (bmi >= 30) {
      risk += 15.0;
    } else if (bmi >= 27) {
      risk += 8.0;
    } else if (bmi >= 25) {
      risk += 5.0;
    } else if (bmi >= 18.5) {
      risk += 1.0;
    } else {
      risk += 3.0;
    }

    // Sleep factor
    if (sleepHours < 5) {
      risk += 8.0;
    } else if (sleepHours < 6) {
      risk += 5.0;
    } else if (sleepHours < 7) {
      risk += 2.0;
    } else if (sleepHours > 9) {
      risk += 2.0;
    }

    // Activity factor
    if (steps < 3000) {
      risk += 10.0;
    } else if (steps < 5000) {
      risk += 6.0;
    } else if (steps < 7000) {
      risk += 3.0;
    } else if (steps < 10000) {
      risk += 1.0;
    } else {
      risk -= 1.0;
    }

    // Blood pressure factor
    if (bloodPressureSystolic != null) {
      if (bloodPressureSystolic > 140) {
        risk += 10.0;
      } else if (bloodPressureSystolic > 120) {
        risk += 5.0;
      }
    }

    return risk.clamp(0.0, 100.0);
  }

  /// Calculate overall health score (0-100)
  static int calculateHealthScore({
    required double bmi,
    required int heartRate,
    required double spO2,
    required double temperature,
    required int steps,
    required double sleepHours,
    required double heartRisk,
  }) {
    int score = 100;

    // BMI contribution (25 points max)
    if (bmi < 18.5) {
      score -= 15;
    } else if (bmi >= 25 && bmi < 30) {
      score -= 10;
    } else if (bmi >= 30) {
      score -= 20;
    }

    // Heart rate contribution (20 points max)
    if (heartRate < 60) {
      score -= 5;
    } else if (heartRate > 100) {
      score -= 15;
    } else if (heartRate > 80) {
      score -= 5;
    }

    // SpO2 contribution (20 points max)
    if (spO2 < 95) {
      score -= 15;
    } else if (spO2 < 97) {
      score -= 5;
    }

    // Temperature contribution (15 points max)
    if (temperature < 36.1 || temperature > 37.2) {
      score -= 10;
    }

    // Activity contribution (10 points max)
    if (steps < 5000) {
      score -= 8;
    } else if (steps < 8000) {
      score -= 4;
    }

    // Sleep contribution (10 points max)
    if (sleepHours < 6) {
      score -= 8;
    } else if (sleepHours < 7) {
      score -= 4;
    }

    // Heart risk contribution (already calculated, subtract from score)
    score -= (heartRisk * 0.2).round();

    return score.clamp(0, 100);
  }

  /// Get health score color
  static int getHealthScoreColor(int score) {
    if (score >= 70) return 0xFF4CAF50; // Green
    if (score >= 40) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get health score status
  static String getHealthScoreStatus(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }

  /// Calculate calories burned based on steps
  static int calculateCaloriesBurned(int steps) {
    // Average: 0.04 calories per step
    return (steps * 0.04).round();
  }

  /// Get stress level from various factors
  static String getStressLevel({
    required int heartRate,
    required double sleepHours,
    required int steps,
  }) {
    int stressScore = 0;

    if (heartRate > 100) stressScore += 3;
    if (heartRate > 80) stressScore += 1;
    if (sleepHours < 6) stressScore += 2;
    if (steps < 5000) stressScore += 2;

    if (stressScore >= 5) return 'High';
    if (stressScore >= 3) return 'Medium';
    return 'Low';
  }

  /// Get water intake recommendation
  static double getRecommendedWaterIntake({
    required double weightKg,
    required int steps,
    required double temperature,
  }) {
    // Base: 30-35ml per kg
    double baseWater = weightKg * 0.033;

    // Add for activity
    if (steps > 10000) {
      baseWater += 0.5;
    } else if (steps > 5000) {
      baseWater += 0.25;
    }

    // Add for high temperature
    if (temperature > 37) {
      baseWater += 0.3;
    }

    return baseWater;
  }

  /// Get food suggestion based on type
  static String getFoodSuggestion(String foodType) {
    switch (foodType.toLowerCase()) {
      case 'junk':
        return '🚨 Reduce junk food intake! Try replacing chips with nuts or fruits.';
      case 'healthy':
        return '✅ Great choice! Keep up with healthy eating habits.';
      case 'mixed':
        return '⚖️ Balance is key. Try adding more vegetables to your meals.';
      default:
        return '🍽️ Make conscious food choices for better health.';
    }
  }

  /// Generate daily health tip based on data
  static String generateHealthTip({
    required int steps,
    required double waterIntake,
    required double sleepHours,
    required int calories,
    required String stressLevel,
  }) {
    List<String> tips = [];

    if (steps < 5000) {
      tips.add('🏃 Aim for at least 10,000 steps today. Start with a 15-minute walk!');
    }
    if (waterIntake < 2) {
      tips.add('💧 Drink more water! Try keeping a water bottle nearby.');
    }
    if (sleepHours < 7) {
      tips.add('😴 You need more sleep! Try going to bed 30 minutes earlier.');
    }
    if (calories > 2500) {
      tips.add('🍔 Watch your calorie intake. Consider lighter meal options.');
    }
    if (stressLevel == 'High') {
      tips.add('🧘 Take time to relax. Try deep breathing exercises.');
    }

    if (tips.isEmpty) {
      tips.add('🌟 Great job! Keep up your healthy habits today!');
    }

    return tips[math.Random().nextInt(tips.length)];
  }

  /// Get mood based on health metrics
  static String getMood({
    required int healthScore,
    required String stressLevel,
  }) {
    if (healthScore >= 70 && stressLevel == 'Low') {
      return '😊';
    } else if (healthScore >= 50) {
      return '😐';
    } else {
      return '😰';
    }
  }

  /// Check for health warnings
  static List<String> getHealthWarnings({
    required int heartRate,
    required int bloodPressureSystolic,
    required int bloodPressureDiastolic,
    required double spO2,
    required double temperature,
  }) {
    List<String> warnings = [];

    if (heartRate > 120 || heartRate < 50) {
      warnings.add('❤️ Abnormal heart rate detected! Consult a doctor if persistent.');
    }
    if (bloodPressureSystolic > 140 || bloodPressureDiastolic > 90) {
      warnings.add('🩺 High blood pressure detected! Monitor regularly.');
    }
    if (spO2 < 95) {
      warnings.add('🫁 Low blood oxygen! Seek medical attention if persistent.');
    }
    if (temperature > 38 || temperature < 35.5) {
      warnings.add('🌡️ Abnormal body temperature! You may have a fever.');
    }

    return warnings;
  }
}
