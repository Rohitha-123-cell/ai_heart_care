import 'heart_model.dart';
/// HeartService replaces app.py (Flask API).
/// Call [predictRisk] directly from any Flutter widget — no server needed.
class HeartService {
  static final HeartService _instance = HeartService._internal();
  factory HeartService() => _instance;
  HeartService._internal() {
    // Train once on first use
    _model.train();
  }

  final HeartModel _model = HeartModel();

  /// Returns heart disease risk as a percentage (0.0 – 100.0).
  ///
  /// Example:
  /// ```dart
  /// final risk = HeartService().predictRisk(
  ///   age: 45, bp: 140, cholesterol: 240,
  ///   smoking: true, diabetes: true,
  /// );
  /// print('Risk: $risk%');
  /// ```
  double predictRisk({
    required double age,
    required double bp,
    required double cholesterol,
    required bool smoking,
    required bool diabetes,
  }) {
    return _model.predictRisk(
      age: age,
      bp: bp,
      cholesterol: cholesterol,
      smoking: smoking ? 1.0 : 0.0,
      diabetes: diabetes ? 1.0 : 0.0,
    );
  }
}
