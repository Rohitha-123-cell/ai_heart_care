import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stress_data.dart';

class StressService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Calculate stress level based on heart rate and activity
  /// 
  /// Stress calculation logic:
  /// - Normal resting HR: 60-100 BPM
  /// - HR above resting indicates stress or activity
  /// - Low activity with high HR = high stress
  /// - High activity with elevated HR = normal physiological response
  /// - Combined score gives overall stress level
  Map<String, dynamic> analyzeStress({
    required int heartRate,
    required int activityLevel, // 0-100 (sedentary to very active)
  }) {
    double stressScore = 0;
    String stressLevel;
    List<String> suggestions = [];

    // Base stress from heart rate
    // Normal resting HR is 60-100 BPM
    double hrStress = 0;
    if (heartRate < 60) {
      hrStress = 10; // Below normal might indicate athlete or medication
    } else if (heartRate < 70) {
      hrStress = 15; // Excellent resting HR
    } else if (heartRate < 80) {
      hrStress = 25; // Good resting HR
    } else if (heartRate < 90) {
      hrStress = 40; // Elevated
    } else if (heartRate < 100) {
      hrStress = 55; // High normal
    } else if (heartRate < 110) {
      hrStress = 70; // Elevated
    } else {
      hrStress = 85; // Very high
    }

    // Activity-adjusted stress
    // If activity is low but HR is high, stress is higher
    // If activity is high and HR is elevated, it's normal
    double activityAdjustment = (activityLevel / 100) * 0.3; // 0-30% adjustment
    double adjustedHrStress = hrStress * (1 - activityAdjustment + 0.3);

    // Calculate final stress score
    double activityStress = activityLevel * 0.2; // Activity contributes 0-20 points
    stressScore = (adjustedHrStress * 0.7) + (activityStress * 0.3);
    stressScore = stressScore.clamp(0, 100);

    // Determine stress level category
    if (stressScore < 25) {
      stressLevel = StressCategory.low;
    } else if (stressScore < 50) {
      stressLevel = StressCategory.moderate;
    } else if (stressScore < 75) {
      stressLevel = StressCategory.high;
    } else {
      stressLevel = StressCategory.veryHigh;
    }

    // Generate personalized suggestions
    suggestions = _generateSuggestions(stressScore, heartRate, activityLevel);

    return {
      'stressScore': stressScore,
      'stressLevel': stressLevel,
      'suggestions': suggestions,
    };
  }

  List<String> _generateSuggestions(double stressScore, int heartRate, int activityLevel) {
    List<String> suggestions = [];

    if (stressScore >= 75) {
      suggestions.addAll([
        "🧘 Practice deep breathing: 4 seconds in, 7 seconds hold, 8 seconds out",
        "🚶 Take a 10-minute walk to reduce stress hormones",
        "📵 Consider a digital detox - step away from screens",
        "🎵 Listen to calming music or nature sounds",
        "💧 Drink water - dehydration can increase cortisol levels",
      ]);
    } else if (stressScore >= 50) {
      suggestions.addAll([
        "🏃 Regular exercise can lower stress by 40% over time",
        "😴 Ensure you're getting 7-9 hours of quality sleep",
        "🧠 Try progressive muscle relaxation before bed",
        "📝 Write down worries to clear your mind",
        "☕ Limit caffeine intake which can amplify stress response",
      ]);
    } else if (stressScore >= 25) {
      suggestions.addAll([
        "✨ Great job managing stress! Keep up your current habits",
        "🧘 Continue mindfulness practices 10 minutes daily",
        "🏋️ Consider adding strength training to your routine",
        "🥗 Maintain a balanced diet rich in omega-3s",
      ]);
    } else {
      suggestions.addAll([
        "🌟 Excellent! Your stress levels are very low",
        "💪 Share your stress management techniques with others",
        "🎯 Challenge yourself with new healthy activities",
        "❤️ Maintain this excellent work-life balance",
      ]);
    }

    // Heart rate specific suggestions
    if (heartRate > 100) {
      suggestions.add("❤️ Your elevated heart rate suggests you may be anxious. Try the 4-7-8 breathing technique.");
    } else if (heartRate < 60) {
      suggestions.add("❤️ Your heart rate is quite low. If you feel dizzy or fatigued, consult a doctor.");
    }

    // Activity specific suggestions
    if (activityLevel < 30) {
      suggestions.add("🚶 Your activity level is low. Try to move more throughout the day.");
    } else if (activityLevel > 70) {
      suggestions.add("💪 Great activity level! Don't forget to rest and recover.");
    }

    return suggestions;
  }

  /// Save stress data to Supabase
  Future<void> saveStressData(StressData stressData) async {
    try {
      await _client.from('stress_data').insert(stressData.toMap());
    } catch (e) {
      print('Error saving stress data: $e');
      throw Exception('Failed to save stress data');
    }
  }

  /// Get user's stress history
  Future<List<StressData>> getStressHistory(String userId) async {
    try {
      final response = await _client
          .from('stress_data')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(30);

      return (response as List)
          .map((item) => StressData.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching stress history: $e');
      return [];
    }
  }

  /// Get latest stress data
  Future<StressData?> getLatestStressData(String userId) async {
    try {
      final response = await _client
          .from('stress_data')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return StressData.fromMap(response[0] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching latest stress data: $e');
      return null;
    }
  }

  /// Simulate activity level based on time of day (placeholder for actual sensor)
  int estimateActivityLevel(DateTime time) {
    int hour = time.hour;
    Random random = Random(time.millisecond);
    
    // Simulate based on time of day
    if (hour >= 6 && hour < 9) {
      return 30 + random.nextInt(20); // Morning routine
    } else if (hour >= 9 && hour < 12) {
      return 40 + random.nextInt(30); // Work hours
    } else if (hour >= 12 && hour < 14) {
      return 50 + random.nextInt(20); // Lunch break
    } else if (hour >= 14 && hour < 18) {
      return 35 + random.nextInt(25); // Afternoon work
    } else if (hour >= 18 && hour < 21) {
      return 60 + random.nextInt(30); // Evening activities
    } else if (hour >= 21 || hour < 6) {
      return 10 + random.nextInt(15); // Night/rest
    }
    return 30;
  }
}
