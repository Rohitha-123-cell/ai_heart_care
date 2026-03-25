import 'package:flutter/material.dart';
import '../../services/risk_prediction_service.dart';
import '../../services/health_data_provider.dart';
import '../../core/utils/responsive.dart';

class RiskPredictionScreen extends StatefulWidget {
  const RiskPredictionScreen({super.key});

  @override
  State<RiskPredictionScreen> createState() => _RiskPredictionScreenState();
}

class _RiskPredictionScreenState extends State<RiskPredictionScreen> {
  final RiskPredictionService _riskService = RiskPredictionService();

  bool _isCalculating = false;
  Map<String, Map<String, dynamic>>? _predictions;

  // Health inputs - Initialize from shared provider
  late double _bmi;
  late int _dailySteps;
  late double _sleepHours;
  late double _heartRisk;
  late int _stressScore;
  bool _smoker = false;
  bool _diabetic = false;
  late int _age;

  @override
  void initState() {
    super.initState();
    // Load data from shared health data provider and clamp to valid slider ranges
    _bmi = healthDataProvider.bmi.clamp(15.0, 40.0);
    _dailySteps = healthDataProvider.steps.clamp(0, 20000);
    _sleepHours = healthDataProvider.sleepHours.clamp(0.0, 12.0);
    _heartRisk = healthDataProvider.heartRisk.clamp(0.0, 100.0);
    _stressScore = healthDataProvider.stressScore.clamp(0, 100);
    _age = healthDataProvider.age.clamp(18, 80);
  }

  Future<void> _calculateRisks() async {
    setState(() {
      _isCalculating = true;
      _predictions = null;
    });

    final result = await _riskService.calculateFutureRisks(
      userId: 'demo_user',
      bmi: _bmi,
      dailySteps: _dailySteps,
      sleepHours: _sleepHours,
      heartRisk: _heartRisk,
      stressScore: _stressScore,
      smoker: _smoker,
      diabetic: _diabetic,
      age: _age,
    );

    setState(() {
      _predictions = result;
      _isCalculating = false;
    });
  }

  Color _getRiskColor(double risk) {
    if (risk < 30) return Colors.green;
    if (risk < 50) return Colors.orange;
    if (risk < 70) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth.clamp(0.0, 520.0).toDouble();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0f2027), const Color(0xFF203a43), const Color(0xFF2c5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
            children: [
              _buildAppBar(width),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      _buildInfoCard(width),
                      SizedBox(height: width * 0.04),
                      _buildInputsCard(width),
                      SizedBox(height: width * 0.04),
                      _buildCalculateButton(width),
                      SizedBox(height: width * 0.04),
                      if (_predictions != null) ...[
                        _buildPredictionResults(width),
                      ],
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: width * 0.06),
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Future Risk Prediction',
                  style: TextStyle(color: Colors.white, fontSize: width * 0.05, fontWeight: FontWeight.bold),
                ),
                Text("Predict your health risks over time", style: TextStyle(color: Colors.white70, fontSize: width * 0.03)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.info_outline, color: Colors.amber, size: width * 0.06),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(
              "Enter your health data to predict future health risks for 1 month, 6 months, and 1 year.",
              style: TextStyle(color: Colors.amber.shade200, fontSize: width * 0.03),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Health Data", style: TextStyle(color: Colors.white, fontSize: width * 0.04, fontWeight: FontWeight.bold)),
          SizedBox(height: width * 0.03),
          _buildSlider("Age", _age.toDouble(), 18, 80, (v) => setState(() => _age = v.round()), "%.0f years"),
          _buildSlider("BMI", _bmi, 15, 40, (v) => setState(() => _bmi = v), "%.1f"),
          _buildSlider("Daily Steps", _dailySteps.toDouble(), 0, 20000, (v) => setState(() => _dailySteps = v.round()), "%.0f"),
          _buildSlider("Sleep (hrs)", _sleepHours, 0, 12, (v) => setState(() => _sleepHours = v), "%.1f"),
          _buildSlider("Heart Risk %", _heartRisk, 0, 100, (v) => setState(() => _heartRisk = v), "%.0f"),
          _buildSlider("Stress %", _stressScore.toDouble(), 0, 100, (v) => setState(() => _stressScore = v.round()), "%.0f"),
          SwitchListTile(
            title: Text("Smoker", style: TextStyle(color: Colors.white70)),
            value: _smoker,
            onChanged: (v) => setState(() => _smoker = v),
            activeColor: Colors.red,
          ),
          SwitchListTile(
            title: Text("Diabetic", style: TextStyle(color: Colors.white70)),
            value: _diabetic,
            onChanged: (v) => setState(() => _diabetic = v),
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged, String format) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(format == "%.0f years" ? "$value years" : (format == "%.0f" ? "${value.round()}" : value.toStringAsFixed(1)), style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.cyan,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.cyan,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildCalculateButton(double width) {
    return GestureDetector(
      onTap: _isCalculating ? null : _calculateRisks,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF667eea), const Color(0xFF764ba2)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCalculating)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Icon(Icons.timeline, color: Colors.white),
            SizedBox(width: 10),
            Text(_isCalculating ? "Calculating..." : "Predict Future Risks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width * 0.04)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResults(double width) {
    return Column(
      children: [
        Text("Risk Predictions", style: TextStyle(color: Colors.white, fontSize: width * 0.05, fontWeight: FontWeight.bold)),
        SizedBox(height: width * 0.04),
        _buildPredictionCard(width, "1 Month", _predictions!['1_month']!),
        _buildPredictionCard(width, "6 Months", _predictions!['6_months']!),
        _buildPredictionCard(width, "1 Year", _predictions!['1_year']!),
      ],
    );
  }

  Widget _buildPredictionCard(double width, String timeframe, Map<String, dynamic> prediction) {
    double riskScore = prediction['risk_score'] ?? 0;
    String riskLevel = prediction['risk_level'] ?? 'Unknown';
    Color riskColor = _getRiskColor(riskScore);

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeframe, style: TextStyle(color: Colors.white, fontSize: width * 0.04, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: riskColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text("$riskLevel", style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          Row(
            children: [
              Text("${riskScore.toStringAsFixed(1)}%", style: TextStyle(color: riskColor, fontSize: width * 0.08, fontWeight: FontWeight.w800)),
              SizedBox(width: width * 0.04),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: riskScore / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(riskColor),
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
