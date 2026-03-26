import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_insight.dart';

class HealthInsightService {
  final String apiKey = "AIzaSyBxG1vXZ-nVU7EpuwOfsV_aAvRThVv76gY";
  final SupabaseClient _client = Supabase.instance.client;

  /// Combine all health data and generate comprehensive insights
  Future<HealthInsight> generateHealthInsight({
    required String userId,
    required CombinedHealthData healthData,
  }) async {
    // Calculate overall health score
    double healthScore = _calculateHealthScore(healthData);
    
    // Identify risk factors
    List<String> riskFactors = _identifyRiskFactors(healthData);
    
    // Generate recommendations
    List<String> recommendations = _generateRecommendations(healthData, riskFactors);
    
    // Get AI analysis
    String aiAnalysis = await _getAIAnalysis(healthData, healthScore);
    
    // Determine overall status
    String overallStatus = _getOverallStatus(healthScore);

    final insight = HealthInsight(
      userId: userId,
      overallStatus: overallStatus,
      healthScore: healthScore,
      riskFactors: riskFactors,
      recommendations: recommendations,
      aiAnalysis: aiAnalysis,
      generatedAt: DateTime.now(),
    );

    // Save to database
    await saveHealthInsight(insight);

    return insight;
  }

  double _calculateHealthScore(CombinedHealthData data) {
    double score = 100;

    // BMI scoring (ideal: 18.5-24.9)
    if (data.bmi < 18.5) {
      score -= (18.5 - data.bmi) * 3;
    } else if (data.bmi > 24.9) {
      score -= (data.bmi - 24.9) * 2;
    }

    // Heart rate scoring (ideal: 60-80)
    if (data.heartRate < 60) {
      score -= (60 - data.heartRate) * 0.5;
    } else if (data.heartRate > 80) {
      score -= (data.heartRate - 80) * 0.8;
    }

    // Steps scoring (goal: 10,000)
    if (data.steps < 5000) {
      score -= (5000 - data.steps) * 0.01;
    } else if (data.steps < 10000) {
      score -= (10000 - data.steps) * 0.005;
    }

    // Sleep scoring (ideal: 7-9 hours)
    if (data.sleepHours < 7) {
      score -= (7 - data.sleepHours) * 5;
    } else if (data.sleepHours > 9) {
      score -= (data.sleepHours - 9) * 3;
    }

    // Heart risk penalty
    score -= data.heartRisk * 0.3;

    // Stress penalty
    score -= data.stressScore * 0.2;

    return score.clamp(0, 100);
  }

  List<String> _identifyRiskFactors(CombinedHealthData data) {
    List<String> risks = [];

    if (data.bmi < 18.5) {
      risks.add("⚠️ Underweight - may need nutritional support");
    } else if (data.bmi > 30) {
      risks.add("⚠️ Obesity - increased risk for heart disease and diabetes");
    } else if (data.bmi > 25) {
      risks.add("⚡ Overweight - consider weight management");
    }

    if (data.heartRate > 100) {
      risks.add("❤️ Elevated heart rate - may indicate stress or anxiety");
    } else if (data.heartRate < 50) {
      risks.add("❤️ Low heart rate - consult doctor if symptomatic");
    }

    if (data.steps < 5000) {
      risks.add("🚶 Low physical activity - increases health risks");
    }

    if (data.sleepHours < 6) {
      risks.add("😴 Insufficient sleep - affects overall health");
    } else if (data.sleepHours > 10) {
      risks.add("😴 Excessive sleep - may indicate underlying issues");
    }

    if (data.heartRisk > 40) {
      risks.add("💔 High cardiovascular risk - medical consultation recommended");
    }

    if (data.stressScore > 60) {
      risks.add("🧠 High stress levels - may impact mental and physical health");
    }

    return risks;
  }

  List<String> _generateRecommendations(CombinedHealthData data, List<String> risks) {
    List<String> recs = [];

    // Priority recommendations based on risks
    if (risks.any((r) => r.contains("Obesity"))) {
      recs.add("🥗 Consult a nutritionist for a personalized diet plan");
      recs.add("🏃 Start with 30 minutes of moderate exercise daily");
    }

    if (risks.any((r) => r.contains("heart rate"))) {
      recs.add("❤️ Practice stress-reduction techniques like meditation");
      recs.add("🩺 Consider getting an ECG if symptoms persist");
    }

    if (risks.any((r) => r.contains("Low physical activity"))) {
      recs.add("🚶 Set hourly reminders to stand and walk");
      recs.add("🏋️ Consider joining a gym or fitness class");
    }

    if (risks.any((r) => r.contains("sleep"))) {
      recs.add("😴 Establish a consistent sleep schedule");
      recs.add("📱 Avoid screens 1 hour before bedtime");
    }

    // General health recommendations
    recs.add("💧 Drink at least 8 glasses of water daily");
    recs.add("🥦 Eat a variety of colorful fruits and vegetables");
    recs.add("😌 Take regular breaks during work");
    recs.add("👨‍⚕️ Schedule annual health checkups");

    return recs;
  }

  String _getOverallStatus(double score) {
    if (score >= 85) return "Excellent";
    if (score >= 70) return "Good";
    if (score >= 50) return "Fair";
    return "Needs Improvement";
  }

  Future<String> _getAIAnalysis(CombinedHealthData data, double score) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey");

      String prompt = """
As a health AI assistant, analyze this user's health metrics and provide a brief, encouraging insight:

**Health Metrics:**
- BMI: ${data.bmi.toStringAsFixed(1)}
- Heart Rate: ${data.heartRate} BPM
- Daily Steps: ${data.steps}
- Sleep: ${data.sleepHours.toStringAsFixed(1)} hours
- Heart Risk: ${data.heartRisk.toStringAsFixed(0)}%
- Stress Score: ${data.stressScore}%
- Calories Burned: ${data.caloriesBurned}

**Overall Health Score:** ${score.toStringAsFixed(0)}/100

Provide a 2-3 sentence encouraging analysis focusing on strengths and one area for improvement. Be supportive and motivational. No disclaimer needed.
""";

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": apiKey,
        },
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }
    } catch (e) {
      print('AI Analysis Error: $e');
    }
    
    // Fallback analysis
    return _generateFallbackAnalysis(data, score);
  }

  String _generateFallbackAnalysis(CombinedHealthData data, double score) {
    List<String> strengths = [];
    List<String> improvements = [];

    if (data.bmi >= 18.5 && data.bmi <= 24.9) {
      strengths.add("healthy weight management");
    }
    if (data.heartRate >= 60 && data.heartRate <= 80) {
      strengths.add("good heart rate");
    }
    if (data.steps >= 8000) {
      strengths.add("excellent activity level");
    }
    if (data.sleepHours >= 7 && data.sleepHours <= 9) {
      strengths.add("proper sleep patterns");
    }

    if (data.bmi > 25) {
      improvements.add("weight management");
    }
    if (data.steps < 8000) {
      improvements.add("increasing daily steps");
    }
    if (data.sleepHours < 7) {
      improvements.add("getting more rest");
    }

    String analysis = "You're doing great with ${strengths.isNotEmpty ? strengths.join(' and ') : 'staying engaged with your health'}. ";
    if (improvements.isNotEmpty) {
      analysis += "Consider focusing on ${improvements.join(' and ')} for better results.";
    }

    return analysis;
  }

  /// Save health insight to Supabase
  Future<void> saveHealthInsight(HealthInsight insight) async {
    try {
      await _client.from('health_insights').insert(insight.toMap());
    } catch (e) {
      print('Error saving health insight: $e');
    }
  }

  /// Get user's health insight history
  Future<List<HealthInsight>> getInsightHistory(String userId) async {
    try {
      final response = await _client
          .from('health_insights')
          .select()
          .eq('user_id', userId)
          .order('generated_at', ascending: false)
          .limit(30);

      return (response as List)
          .map((item) => HealthInsight.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching insight history: $e');
      return [];
    }
  }

  /// Get latest health insight
  Future<HealthInsight?> getLatestInsight(String userId) async {
    try {
      final response = await _client
          .from('health_insights')
          .select()
          .eq('user_id', userId)
          .order('generated_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return HealthInsight.fromMap(response[0] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching latest insight: $e');
      return null;
    }
  }
}
