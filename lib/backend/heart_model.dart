import 'dart:math';

/// Dart implementation of Logistic Regression (replaces heart_model.py)
/// Trains on sample heart-disease data using gradient descent.
class HeartModel {
  List<double> _weights = [];
  double _bias = 0.0;
  bool _isTrained = false;

  // ── Sample training data (mirrors heart_model.py) ──────────────────────────
  static const List<List<double>> _trainX = [
    [25, 120, 200, 0, 0],
    [45, 140, 240, 1, 1],
    [50, 150, 260, 1, 0],
    [35, 130, 210, 0, 0],
    [60, 160, 300, 1, 1],
  ];
  static const List<double> _trainY = [0, 1, 1, 0, 1];

  // ── Sigmoid ─────────────────────────────────────────────────────────────────
  double _sigmoid(double z) => 1.0 / (1.0 + exp(-z));

  // ── Forward pass ────────────────────────────────────────────────────────────
  double _forward(List<double> x) {
    double z = _bias;
    for (int i = 0; i < _weights.length; i++) {
      z += _weights[i] * x[i];
    }
    return _sigmoid(z);
  }

  // ── Feature scaling (standardize each column) ────────────────────────────
  late List<double> _mean;
  late List<double> _std;

  void _computeScaling() {
    int m = _trainX.length;
    int n = _trainX[0].length;
    _mean = List.filled(n, 0.0);
    _std = List.filled(n, 1.0);

    for (int j = 0; j < n; j++) {
      double sum = 0;
      for (int i = 0; i < m; i++) { sum += _trainX[i][j]; }
      _mean[j] = sum / m;

      double variance = 0;
      for (int i = 0; i < m; i++) {
        variance += pow(_trainX[i][j] - _mean[j], 2);
      }
      _std[j] = sqrt(variance / m);
      if (_std[j] == 0) _std[j] = 1.0; // avoid division by zero
    }
  }

  List<double> _scale(List<double> x) {
    return List.generate(
        x.length, (j) => (x[j] - _mean[j]) / _std[j]);
  }

  // ── Train with gradient descent ──────────────────────────────────────────
  void train({int epochs = 3000, double lr = 0.1}) {
    _computeScaling();

    int m = _trainX.length;
    int n = _trainX[0].length;

    // Scale training features
    List<List<double>> X =
        _trainX.map((row) => _scale(row)).toList();

    _weights = List.filled(n, 0.0);
    _bias = 0.0;

    for (int epoch = 0; epoch < epochs; epoch++) {
      List<double> preds = X.map((xi) => _forward(xi)).toList();

      List<double> dw = List.filled(n, 0.0);
      double db = 0.0;

      for (int i = 0; i < m; i++) {
        double error = preds[i] - _trainY[i];
        for (int j = 0; j < n; j++) {
          dw[j] += error * X[i][j];
        }
        db += error;
      }

      for (int j = 0; j < n; j++) {
        _weights[j] -= lr * dw[j] / m;
      }
      _bias -= lr * db / m;
    }

    _isTrained = true;
  }

  /// Returns the probability (0–100) of heart disease risk.
  double predictRisk({
    required double age,
    required double bp,
    required double cholesterol,
    required double smoking, // 0 or 1
    required double diabetes, // 0 or 1
  }) {
    if (!_isTrained) train();

    final scaled = _scale([age, bp, cholesterol, smoking, diabetes]);
    final prob = _forward(scaled);
    return double.parse((prob * 100).toStringAsFixed(2));
  }
}
