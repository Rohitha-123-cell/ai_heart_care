import 'package:supabase_flutter/supabase_flutter.dart';

class RiskPredictionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Calculate future health risks based on current health data
  Future<Map<String, Map<String, dynamic>>> calculateFutureRisks({
    required String userId,
    required double bmi,
    required int dailySteps,
    required double sleepHours,
    required double heartRisk,
    required int stressScore,
    required bool smoker,
    required bool diabetic,
    required int age,
  }) async {
    // Risk factors weights (0-100 scale)
    double bmiRisk = _calculateBMIRisk(bmi);
    double activityRisk = _calculateActivityRisk(dailySteps);
    double sleepRisk = _calculateSleepRisk(sleepHours);
    double lifestyleRisk = _calculateLifestyleRisk(
      heartRisk: heartRisk,
      stressScore: stressScore,
      smoker: smoker,
      diabetic: diabetic,
    );

    // Calculate composite risk score
    double compositeRisk = (bmiRisk * 0.2) +
        (activityRisk * 0.25) +
        (sleepRisk * 0.15) +
        (lifestyleRisk * 0.4);

    // Generate predictions for different timeframes
    Map<String, Map<String, dynamic>> predictions = {
      '1_month': _predictRisk(compositeRisk, 0.08, age, bmiRisk > 50),
      '6_months': _predictRisk(compositeRisk, 0.35, age, bmiRisk > 40),
      '1_year': _predictRisk(compositeRisk, 0.6, age, bmiRisk > 30),
    };

    // Save predictions
    await _saveRiskPrediction(userId, predictions);

    return predictions;
  }

  double _calculateBMIRisk(double bmi) {
    if (bmi < 18.5) return 30 + ((18.5 - bmi) * 5);
    if (bmi < 25) return 10 + ((bmi - 18.5) * 2);
    if (bmi < 30) return 40 + ((bmi - 25) * 4);
    return 60 + ((bmi - 30) * 3);
  }

  double _calculateActivityRisk(int steps) {
    if (steps >= 10000) return 10;
    if (steps >= 8000) return 20;
    if (steps >= 5000) return 40;
    if (steps >= 3000) return 60;
    return 80;
  }

  double _calculateSleepRisk(double hours) {
    if (hours >= 7 && hours <= 9) return 10;
    if (hours >= 6 && hours < 7) return 30;
    if (hours > 9) return 25;
    if (hours >= 5) return 50;
    return 70;
  }

  double _calculateLifestyleRisk({
    required double heartRisk,
    required int stressScore,
    required bool smoker,
    required bool diabetic,
  }) {
    double risk = heartRisk * 0.4;
    risk += stressScore * 0.2;
    if (smoker) risk += 25;
    if (diabetic) risk += 20;
    return risk.clamp(0, 100);
  }

  Map<String, dynamic> _predictRisk(double baseRisk, double timeFactor, int age, bool highBMIFlag) {
    double riskIncrease = baseRisk * timeFactor;
    
    // Age factor
    if (age > 50) riskIncrease *= 1.3;
    else if (age > 40) riskIncrease *= 1.15;
    else if (age < 30) riskIncrease *= 0.85;

    // High BMI accelerates risk
    if (highBMIFlag) riskIncrease *= 1.2;

    double predictedRisk = baseRisk + riskIncrease;
    predictedRisk = predictedRisk.clamp(0, 100);

    // Generate timeline events
    List<Map<String, String>> timeline = [];
    
    if (predictedRisk > 60) {
      timeline.add({
        'timeframe': 'Immediate',
        'condition': 'Elevated stress levels',
        'action': 'Schedule check-up',
      });
    }
    if (predictedRisk > 40) {
      timeline.add({
        'timeframe': '3-6 months',
        'condition': 'Cardiovascular concerns',
        'action': 'Monitor blood pressure',
      });
    }
    if (predictedRisk > 25) {
      timeline.add({
        'timeframe': '1 year',
        'condition': 'Weight management',
        'action': 'Diet and exercise plan',
      });
    }

    return {
      'risk_score': predictedRisk,
      'risk_level': _getRiskLevel(predictedRisk),
      'timeline': timeline,
      'recommendations': _getRecommendations(predictedRisk),
    };
  }

  String _getRiskLevel(double risk) {
    if (risk < 20) return "Low";
    if (risk < 40) return "Moderate";
    if (risk < 60) return "High";
    return "Very High";
  }

  List<String> _getRecommendations(double risk) {
    List<String> recs = [];
    
    if (risk > 50) {
      recs.add("🚨 Consult a healthcare professional immediately");
      recs.add("💊 Review current medications with your doctor");
      recs.add("📊 Schedule comprehensive health screening");
    } else if (risk > 30) {
      recs.add("❤️ Regular cardiovascular monitoring recommended");
      recs.add("🏃 Increase physical activity to 150 min/week");
      recs.add("🥗 Consider dietary changes");
    } else {
      recs.add("✨ Maintain current healthy lifestyle");
      recs.add("📅 Keep regular health check-ups");
      recs.add("🧘 Continue stress management practices");
    }
    
    return recs;
  }

  Future<void> _saveRiskPrediction(String userId, Map<String, Map<String, dynamic>> predictions) async {
    try {
      await _client.from('risk_predictions').upsert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String(),
        'predictions': predictions.toString(),
        '1_month_risk': predictions['1_month']!['risk_score'],
        '6_months_risk': predictions['6_months']!['risk_score'],
        '1_year_risk': predictions['1_year']!['risk_score'],
      });
    } catch (e) {
      print('Error saving risk prediction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRiskHistory(String userId) async {
    try {
      final response = await _client
          .from('risk_predictions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(12);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching risk history: $e');
      return [];
    }
  }
}
