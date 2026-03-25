import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AICopilotService {
  final String apiKey = "AIzaSyAjz06R1BDvoUZyM_HhOiGuf8SFTznKu-M";
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getPersonalizedRecommendations({
    required String userId,
    String? symptoms,
    int? steps,
    double? heartRisk,
    double? bmi,
    double? sleepHours,
    int? stressScore,
  }) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey");

      String prompt = '''
You are an AI Health Copilot providing personalized health recommendations.

User Health Profile:
- BMI: ${bmi?.toStringAsFixed(1) ?? 'Not recorded'}
- Daily Steps: ${steps ?? 0}
- Heart Risk: ${heartRisk?.toStringAsFixed(0) ?? '0'}%
- Sleep: ${sleepHours?.toStringAsFixed(1) ?? '0'} hours
- Stress Level: ${stressScore ?? 0}%
- Symptoms: ${symptoms ?? 'None reported'}

Provide 4-5 personalized, actionable health recommendations in bullet points. Format as emoji-prefixed bullet points. No disclaimer needed.
''';

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "X-goog-api-key": apiKey},
        body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }
    } catch (e) {
      print('AI Copilot Error: $e');
    }
    
    return _generateFallbackRecommendations(steps, heartRisk, bmi, sleepHours, stressScore);
  }

  String _generateFallbackRecommendations(int? steps, double? heartRisk, double? bmi, double? sleepHours, int? stressScore) {
    List<String> recommendations = [];

    if (steps != null && steps < 8000) {
      recommendations.add("🚶 Try to increase your daily steps by 500 each week");
    } else if (steps != null) {
      recommendations.add("💪 Great job! Consider adding strength training");
    }

    if (heartRisk != null && heartRisk > 40) {
      recommendations.add("❤️ Heart risk elevated - consult your doctor");
    }

    if (bmi != null && (bmi < 18.5 || bmi > 25)) {
      recommendations.add("⚖️ Consider consulting a nutritionist");
    }

    if (sleepHours != null && sleepHours < 7) {
      recommendations.add("😴 Aim for 7-8 hours of sleep");
    }

    if (stressScore != null && stressScore > 50) {
      recommendations.add("🧘 Try 10 minutes of meditation daily");
    }

    if (recommendations.isEmpty) {
      recommendations.add("🌟 You're doing well!");
      recommendations.add("📅 Keep up regular health check-ups");
    }

    return recommendations.join('\n');
  }

  Future<String> chat(String userMessage) async {
    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey");

      String prompt = 'You are an AI Health Copilot. User asked: "$userMessage". Keep response concise (2-3 sentences). No disclaimer needed.';

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "X-goog-api-key": apiKey},
        body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }
    } catch (err) {
      print('AI Chat Error: $err');
    }
    
    return "I am here to help with your health questions!";
  }

  Future<void> saveUserHealthData({
    required String userId,
    String? symptoms,
    int? steps,
    double? heartRisk,
    double? bmi,
    double? sleepHours,
    int? stressScore,
    String? recommendations,
  }) async {
    try {
      await _client.from('health_data').upsert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'symptoms': symptoms,
        'steps': steps,
        'heart_risk': heartRisk,
        'bmi': bmi,
        'sleep_hours': sleepHours,
        'stress_score': stressScore,
        'recommendations': recommendations,
      });
    } catch (e) {
      print('Error saving health data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHealthHistory(String userId) async {
    try {
      final response = await _client
          .from('health_data')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching health history: $e');
      return [];
    }
  }
}
