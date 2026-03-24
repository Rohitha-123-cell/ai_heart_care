import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class HealthDataService {
  static final SupabaseClient _client = SupabaseService.client;

  // Save health data for the current user
  static Future<void> saveHealthData({
    required double bmi,
    required double heartRisk,
    required double sleepHours,
    required int steps,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('health_data').insert({
      'user_id': user.id,
      'bmi': bmi,
      'heart_risk': heartRisk,
      'sleep_hours': sleepHours,
      'steps': steps,
    });
  }

  // Get latest health data for the current user
  static Future<Map<String, dynamic>?> getLatestHealthData() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('health_data')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .limit(1);

    if (response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  // Get user's health history
  static Future<List<Map<String, dynamic>>> getHealthHistory({int limit = 30}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('health_data')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .limit(limit);

    return response.map((e) => e as Map<String, dynamic>).toList();
  }

  // Get health summary (latest + averages)
  static Future<Map<String, dynamic>?> getHealthSummary() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client.rpc('get_user_health_summary', params: {
      'user_uuid': user.id,
    });

    if (response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  // Update existing health data
  static Future<void> updateHealthData({
    required int id,
    required double bmi,
    required double heartRisk,
    required double sleepHours,
    required int steps,
  }) async {
    await _client.from('health_data').update({
      'bmi': bmi,
      'heart_risk': heartRisk,
      'sleep_hours': sleepHours,
      'steps': steps,
    }).eq('id', id);
  }

  // Delete health data
  static Future<void> deleteHealthData(int id) async {
    await _client.from('health_data').delete().eq('id', id);
  }
}
