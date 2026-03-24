import 'package:flutter/material.dart';
import '../../models/health_insight.dart';
import '../../services/health_insight_service.dart';

class AIHealthInsightScreen extends StatefulWidget {
  const AIHealthInsightScreen({super.key});

  @override
  State<AIHealthInsightScreen> createState() => _AIHealthInsightScreenState();
}

class _AIHealthInsightScreenState extends State<AIHealthInsightScreen>
    with TickerProviderStateMixin {
  final HealthInsightService _insightService = HealthInsightService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isGenerating = false;
  HealthInsight? _currentInsight;
  
  // Sample data inputs
  double _bmi = 24.0;
  int _heartRate = 72;
  int _steps = 8500;
  double _sleepHours = 7.5;
  double _heartRisk = 25.0;
  int _stressScore = 35;
  int _caloriesBurned = 320;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateInsight() async {
    setState(() {
      _isGenerating = true;
    });

    final healthData = CombinedHealthData(
      bmi: _bmi,
      heartRate: _heartRate,
      steps: _steps,
      sleepHours: _sleepHours,
      heartRisk: _heartRisk,
      stressScore: _stressScore,
      caloriesBurned: _caloriesBurned,
    );

    final insight = await _insightService.generateHealthInsight(
      userId: 'demo_user',
      healthData: healthData,
    );

    setState(() {
      _currentInsight = insight;
      _isGenerating = false;
    });

    _fadeController.forward(from: 0);
  }

  Color _getStatusColor() {
    if (_currentInsight == null) return Colors.grey;
    switch (_currentInsight!.overallStatus) {
      case "Excellent":
        return Colors.green;
      case "Good":
        return Colors.lightGreen;
      case "Fair":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0f2027),
              const Color(0xFF203a43),
              const Color(0xFF2c5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(width),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      _buildHealthScoreCard(width),
                      SizedBox(height: width * 0.04),
                      _buildInputSection(width),
                      SizedBox(height: width * 0.04),
                      _buildGenerateButton(width),
                      SizedBox(height: width * 0.04),
                      if (_currentInsight != null) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildInsightResults(width),
                        ),
                      ],
                      SizedBox(height: width * 0.04),
                      _buildAdvancedInfoCard(width),
                    ],
                  ),
                ),
              ),
            ],
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI Health Insight',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge("🤖 AI Powered", Colors.purple),
                    SizedBox(width: width * 0.02),
                    _buildBadge("📊 Combined Data", Colors.blue),
                    SizedBox(width: width * 0.02),
                    _buildBadge("✨ Advanced", Colors.cyan),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHealthScoreCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.3),
            _getStatusColor().withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _getStatusColor().withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isGenerating ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.all(width * 0.05),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getStatusColor(), _getStatusColor().withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.insights,
                    color: Colors.white,
                    size: width * 0.1,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.04),
          Text(
            _currentInsight?.overallStatus ?? "Ready to Analyze",
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.01),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Health Score: ${_currentInsight?.healthScore.toStringAsFixed(0) ?? "0"}/100",
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.035,
              ),
            ),
          ),
          if (_isGenerating) ...[
            SizedBox(height: width * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _getStatusColor(),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Analyzing your health data...",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.03,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune, color: Colors.cyan, size: 18),
              ),
              SizedBox(width: 12),
              Text(
                "Health Parameters",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          _buildSlider("BMI", _bmi, 15, 40, (v) => setState(() => _bmi = v), "%.1f"),
          _buildSlider("Heart Rate", _heartRate.toDouble(), 40, 120, (v) => setState(() => _heartRate = v.round()), "%.0f BPM"),
          _buildSlider("Steps", _steps.toDouble(), 0, 20000, (v) => setState(() => _steps = v.round()), "%.0f"),
          _buildSlider("Sleep", _sleepHours, 0, 12, (v) => setState(() => _sleepHours = v), "%.1f hrs"),
          _buildSlider("Heart Risk", _heartRisk, 0, 100, (v) => setState(() => _heartRisk = v), "%.0f%%"),
          _buildSlider("Stress Score", _stressScore.toDouble(), 0, 100, (v) => setState(() => _stressScore = v.round()), "%.0f%%"),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String format,
  ) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: width * 0.03),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                format == "%.1f"
                    ? (format.contains("hrs") ? "${value.toStringAsFixed(1)} hrs" : value.toStringAsFixed(1))
                    : format == "%.0f BPM"
                        ? "${value.round()} BPM"
                        : format == "%.0f%%"
                            ? "${value.round()}%"
                            : "${value.round()}",
                style: TextStyle(color: Colors.cyan, fontSize: width * 0.03, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.cyan,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: Colors.cyan,
            overlayColor: Colors.cyan.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(double width) {
    return GestureDetector(
      onTap: _isGenerating ? null : _generateInsight,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGenerating)
              SizedBox(
                width: width * 0.05,
                height: width * 0.05,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(Icons.auto_awesome, color: Colors.white, size: width * 0.05),
            SizedBox(width: width * 0.02),
            Text(
              _isGenerating ? "Analyzing..." : "Generate AI Insight",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightResults(double width) {
    return Column(
      children: [
        // AI Analysis
        _buildInsightCard(
          width,
          "AI Analysis",
          Icons.psychology,
          Colors.purple,
          _currentInsight!.aiAnalysis,
        ),
        SizedBox(height: width * 0.03),

        // Risk Factors
        if (_currentInsight!.riskFactors.isNotEmpty)
          _buildListCard(
            width,
            "Risk Factors",
            Icons.warning_amber,
            Colors.orange,
            _currentInsight!.riskFactors,
          ),
        SizedBox(height: width * 0.03),

        // Recommendations
        if (_currentInsight!.recommendations.isNotEmpty)
          _buildListCard(
            width,
            "Recommendations",
            Icons.recommend,
            Colors.green,
            _currentInsight!.recommendations,
          ),
      ],
    );
  }

  Widget _buildInsightCard(
    double width,
    String title,
    IconData icon,
    Color color,
    String content,
  ) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: width * 0.05),
              ),
              SizedBox(width: width * 0.03),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.032,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    double width,
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: width * 0.05),
              ),
              SizedBox(width: width * 0.03),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
              SizedBox(width: width * 0.02),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${items.length}",
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          ...items.take(5).map((item) => Padding(
                padding: EdgeInsets.only(bottom: width * 0.025),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdvancedInfoCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.info_outline, color: Colors.amber, size: width * 0.05),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Advanced Analysis",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.035,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Our AI analyzes multiple health parameters to provide personalized insights and recommendations.",
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: width * 0.028,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
