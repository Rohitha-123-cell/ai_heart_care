import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class StorageService {
  static final SupabaseClient _client = SupabaseService.client;

  // Save symptoms
  static Future<void> saveSymptoms({
    required String symptoms,
    required String diagnosis,
    required double riskScore,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('symptoms').insert({
      'user_id': user.id,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'risk_score': riskScore,
    });
  }

  // Get symptoms history
  static Future<List<Map<String, dynamic>>> getSymptomsHistory({int limit = 30}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }

  // Save risk scores
  static Future<void> saveRiskScore({
    required String riskType,
    required double score,
    required String level,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('risk_scores').insert({
      'user_id': user.id,
      'risk_type': riskType,
      'score': score,
      'level': level,
    });
  }

  // Get risk scores history
  static Future<List<Map<String, dynamic>>> getRiskScoresHistory({
    String? riskType,
    int limit = 30,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    if (riskType != null) {
      final response = await _client
          .from('risk_scores')
          .select()
          .eq('user_id', user.id)
          .eq('risk_type', riskType)
          .order('created_at', ascending: false)
          .limit(limit);
      return response.map((e) => e as Map<String, dynamic>).toList();
    }

    final response = await _client
        .from('risk_scores')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }

  // Save health metrics (for weekly trends)
  static Future<void> saveHealthMetrics({
    required double bmi,
    required double heartRate,
    required double bloodPressure,
    required double weight,
    required double sleepHours,
    required int steps,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('health_metrics').insert({
      'user_id': user.id,
      'bmi': bmi,
      'heart_rate': heartRate,
      'blood_pressure': bloodPressure,
      'weight': weight,
      'sleep_hours': sleepHours,
      'steps': steps,
    });
  }

  // Get weekly health metrics
  static Future<List<Map<String, dynamic>>> getWeeklyMetrics() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Get last 7 days of data
    final response = await _client
        .from('health_metrics')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(7);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }

  // Get BMI history for chart
  static Future<List<Map<String, dynamic>>> getBmiHistory({int limit = 30}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('health_metrics')
        .select('created_at, bmi')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }

  // Get heart risk history for chart
  static Future<List<Map<String, dynamic>>> getHeartRiskHistory({int limit = 30}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('risk_scores')
        .select()
        .eq('user_id', user.id)
        .eq('risk_type', 'heart')
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }
}
