import 'package:flutter/material.dart';

/// Global provider for health data that is shared across all screens
/// This stores the health data entered by the user in HealthInputScreen
/// and makes it available to Dashboard, RiskPrediction, and HealthReport screens
class HealthDataProvider extends ChangeNotifier {
  // Current health input data
  double _bmi = 24.0;
  int _age = 30;
  int _steps = 8000;
  double _sleepHours = 7.0;
  double _heartRisk = 25.0;
  double _heartRate = 72.0;
  double _weight = 70.0;
  double _height = 170.0;
  int _stressScore = 35;
  
  // BMI category
  String _bmiCategory = "Normal";
  
  // Historical data for trends (last 7 days)
  List<double> _heartRiskHistory = [35.0, 40.0, 38.0, 42.0, 35.0, 30.0, 28.0];
  List<double> _bmiHistory = [24.5, 24.3, 24.4, 24.2, 24.1, 24.0, 23.9];
  List<int> _stepsHistory = [6500, 7200, 8000, 7500, 9000, 8500, 10000];
  List<double> _sleepHistory = [6.5, 7.0, 7.5, 8.0, 7.0, 7.5, 8.0];
  
  // Getters for current data
  double get bmi => _bmi;
  int get age => _age;
  int get steps => _steps;
  double get sleepHours => _sleepHours;
  double get heartRisk => _heartRisk;
  double get heartRate => _heartRate;
  double get weight => _weight;
  double get height => _height;
  int get stressScore => _stressScore;
  String get bmiCategory => _bmiCategory;
  
  // Getters for historical data (trends)
  List<double> get heartRiskHistory => _heartRiskHistory;
  List<double> get bmiHistory => _bmiHistory;
  List<double> get stepsHistory => _stepsHistory.map((e) => e.toDouble()).toList();
  List<double> get sleepHistory => _sleepHistory;
  
  // Today's date key for tracking
  String _todayKey = "";
  
  // Check if data was already updated today
  bool get isDataUpdatedToday {
    final today = DateTime.now().toString().substring(0, 10);
    return _todayKey == today;
  }
  
  // Update historical data: appends a new entry on a new day,
  // or updates today's last entry for same-day calls.
  void _updateDailyData() {
    final today = DateTime.now().toString().substring(0, 10);

    if (_todayKey != today) {
      // New day — append entries, keep max 7 days
      if (_heartRiskHistory.length >= 7) _heartRiskHistory.removeAt(0);
      _heartRiskHistory.add(_heartRisk);

      if (_bmiHistory.length >= 7) _bmiHistory.removeAt(0);
      _bmiHistory.add(_bmi);

      if (_stepsHistory.length >= 7) _stepsHistory.removeAt(0);
      _stepsHistory.add(_steps);

      if (_sleepHistory.length >= 7) _sleepHistory.removeAt(0);
      _sleepHistory.add(_sleepHours);

      _todayKey = today;
    } else {
      // Same day — update the most recent entry with current values
      if (_heartRiskHistory.isNotEmpty) _heartRiskHistory[_heartRiskHistory.length - 1] = _heartRisk;
      if (_bmiHistory.isNotEmpty) _bmiHistory[_bmiHistory.length - 1] = _bmi;
      if (_stepsHistory.isNotEmpty) _stepsHistory[_stepsHistory.length - 1] = _steps;
      if (_sleepHistory.isNotEmpty) _sleepHistory[_sleepHistory.length - 1] = _sleepHours;
    }
  }
  
  // Setters - also update today's historical data for real-time trends
  void setHealthData({
    double? bmi,
    int? age,
    int? steps,
    double? sleepHours,
    double? heartRisk,
    double? heartRate,
    double? weight,
    double? height,
    int? stressScore,
    String? bmiCategory,
  }) {
    if (bmi != null) _bmi = bmi;
    if (age != null) _age = age;
    if (steps != null) _steps = steps;
    if (sleepHours != null) _sleepHours = sleepHours;
    if (heartRisk != null) _heartRisk = heartRisk;
    if (heartRate != null) _heartRate = heartRate;
    if (weight != null) _weight = weight;
    if (height != null) _height = height;
    if (stressScore != null) _stressScore = stressScore;
    if (bmiCategory != null) _bmiCategory = bmiCategory;
    
    // Append a new daily entry or update today's entry
    _updateDailyData();

    notifyListeners();
  }
  
  // Calculate BMI from height and weight
  void calculateBMI() {
    if (_height > 0 && _weight > 0) {
      double heightInMeters = _height / 100;
      _bmi = _weight / (heightInMeters * heightInMeters);
      _bmi = double.parse(_bmi.toStringAsFixed(1));
      
      if (_bmi < 18.5) {
        _bmiCategory = "Underweight";
      } else if (_bmi < 25) {
        _bmiCategory = "Normal";
      } else if (_bmi < 30) {
        _bmiCategory = "Overweight";
      } else {
        _bmiCategory = "Obese";
      }
      notifyListeners();
    }
  }
  
  // Calculate heart risk based on age and BMI
  void calculateHeartRisk() {
    double risk = 0;
    
    // Age factor
    if (_age < 30) risk += 5;
    else if (_age < 40) risk += 10;
    else if (_age < 50) risk += 20;
    else if (_age < 60) risk += 30;
    else risk += 40;
    
    // BMI factor
    if (_bmi >= 30) risk += 25;
    else if (_bmi >= 25) risk += 15;
    else risk += 5;
    
    _heartRisk = risk > 100 ? 100 : risk;
    notifyListeners();
  }
  
  // Reset all data
  void reset() {
    _bmi = 24.0;
    _age = 30;
    _steps = 8000;
    _sleepHours = 7.0;
    _heartRisk = 25.0;
    _heartRate = 72.0;
    _weight = 70.0;
    _height = 170.0;
    _stressScore = 35;
    _bmiCategory = "Normal";
    notifyListeners();
  }
}

// Global instance for easy access
final healthDataProvider = HealthDataProvider();
