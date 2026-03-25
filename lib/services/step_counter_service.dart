import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class StepCounterService {
  final SupabaseClient _client = Supabase.instance.client;
  
  Timer? _simulationTimer;
  
  int _todaySteps = 0;
  int _dailyGoal = 10000;
  DateTime? _lastReset;
  DateTime? _sessionStart;
  List<int> _hourlySteps = List.filled(24, 0);
  
  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  double get progress => (_todaySteps / _dailyGoal).clamp(0.0, 1.0);
  int get stepsRemaining => (_dailyGoal - _todaySteps).clamp(0, _dailyGoal);
  double get distanceKm => _todaySteps * 0.0007; // Approximate
  double get caloriesBurned => _todaySteps * 0.04; // Approximate

  /// Initialize step counter
  Future<void> initialize() async {
    try {
      // Check if it's a new day and reset
      _checkDayReset();
      _sessionStart = DateTime.now();
    } catch (e) {
      debugPrint('Step counter initialization error: $e');
    }
  }

  void _checkDayReset() {
    DateTime now = DateTime.now();
    if (_lastReset == null || 
        now.day != _lastReset!.day || 
        now.month != _lastReset!.month ||
        now.year != _lastReset!.year) {
      _todaySteps = 0;
      _lastReset = now;
      _hourlySteps = List.filled(24, 0);
    }
  }

  StreamController<int>? _streamController;

  /// Start step counting simulation
  Stream<int> startCounting() {
    _streamController?.close();
    _streamController = StreamController<int>.broadcast();
    StreamController<int> controller = _streamController!;
    Random random = Random();
    
    // Simulate ~100 steps per 10 minutes on average
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate activity pattern
      int hour = DateTime.now().hour;
      int baseSteps;
      
      // More activity during active hours
      if (hour >= 7 && hour <= 9) {
        baseSteps = 15 + random.nextInt(10); // Morning walk
      } else if (hour >= 12 && hour <= 13) {
        baseSteps = 10 + random.nextInt(8); // Lunch walk
      } else if (hour >= 17 && hour <= 19) {
        baseSteps = 20 + random.nextInt(12); // Evening exercise
      } else if (hour >= 22 || hour < 6) {
        baseSteps = 0; // Sleep time
      } else {
        baseSteps = 5 + random.nextInt(8); // Regular activity
      }
      
      _todaySteps += baseSteps;
      
      // Track hourly progress
      int currentHour = DateTime.now().hour;
      _hourlySteps[currentHour] += baseSteps;
      
      controller.add(_todaySteps);
    });

    return controller.stream;
  }

  /// Stop step counting
  void stopCounting() {
    _simulationTimer?.cancel();
    _streamController?.close();
    _streamController = null;
    _saveDailyProgress();
  }

  /// Set daily step goal
  void setDailyGoal(int goal) {
    _dailyGoal = goal;
  }

  /// Get progress percentage
  double getProgressPercentage() {
    return (progress * 100).clamp(0, 100);
  }

  /// Get motivational message based on progress
  String getMotivationalMessage() {
    double pct = getProgressPercentage();
    if (pct == 0) {
      return "🌅 Let's get moving! Start your day with some steps.";
    } else if (pct < 25) {
      return "🚀 Great start! Keep the momentum going!";
    } else if (pct < 50) {
      return "💪 Halfway there! You're doing amazing!";
    } else if (pct < 75) {
      return "🔥 Almost there! Push through to your goal!";
    } else if (pct < 100) {
      return "🎉 So close! Just a few more steps!";
    } else {
      return "🏆 Goal achieved! You're a step champion!";
    }
  }

  /// Get time needed to reach goal at current pace
  String getTimeToGoal() {
    if (_todaySteps == 0 || _sessionStart == null) return "--";
    
    Duration elapsed = DateTime.now().difference(_sessionStart!);
    double stepsPerMinute = _todaySteps / elapsed.inMinutes.clamp(1, double.infinity);
    
    if (stepsPerMinute <= 0) return "--";
    
    int stepsRemaining = _dailyGoal - _todaySteps;
    if (stepsRemaining <= 0) return "Goal reached!";
    
    int minutesNeeded = (stepsRemaining / stepsPerMinute).ceil();
    
    if (minutesNeeded < 60) {
      return "$minutesNeeded min";
    } else {
      int hours = minutesNeeded ~/ 60;
      int mins = minutesNeeded % 60;
      return "${hours}h ${mins}m";
    }
  }

  /// Get hourly step data
  List<int> getHourlySteps() {
    return List.from(_hourlySteps);
  }

  /// Get weekly summary
  Map<String, dynamic> getWeeklySummary(List<int> weekSteps) {
    int total = weekSteps.fold(0, (sum, steps) => sum + steps);
    double avg = total / 7;
    int best = weekSteps.isEmpty ? 0 : weekSteps.reduce((a, b) => a > b ? a : b);
    int worst = weekSteps.isEmpty ? 0 : weekSteps.reduce((a, b) => a < b ? a : b);
    
    return {
      'total': total,
      'average': avg.round(),
      'best': best,
      'worst': worst,
      'goalMet': weekSteps.where((s) => s >= _dailyGoal).length,
    };
  }

  /// Save daily progress to Supabase
  Future<void> _saveDailyProgress() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('step_data').upsert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'steps': _todaySteps,
        'goal': _dailyGoal,
        'hourly_steps': _hourlySteps.join(','),
      });
    } catch (e) {
      debugPrint('Error saving step data: $e');
    }
  }

  /// Get weekly step data
  Future<List<int>> getWeeklySteps(String userId) async {
    try {
      List<int> weekSteps = [];
      DateTime now = DateTime.now();
      
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dateStr = date.toIso8601String().split('T')[0];
        
        final response = await _client
            .from('step_data')
            .select()
            .eq('user_id', userId)
            .eq('date', dateStr)
            .limit(1);
        
        if (response.isNotEmpty) {
          weekSteps.add(response[0]['steps'] ?? 0);
        } else {
          weekSteps.add(0);
        }
      }
      
      return weekSteps;
    } catch (e) {
      debugPrint('Error fetching weekly steps: $e');
      return List.filled(7, 0);
    }
  }

  /// Set steps manually (for testing)
  void setSteps(int steps) {
    _todaySteps = steps;
  }

  /// Dispose resources
  void dispose() {
    _simulationTimer?.cancel();
  }
}
