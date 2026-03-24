import 'package:flutter/material.dart';
import '../../services/report_generator_service.dart';
import '../../services/health_data_provider.dart';
class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});
  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}
class _HealthReportScreenState extends State<HealthReportScreen> with SingleTickerProviderStateMixin {
  final ReportGeneratorService _reportService = ReportGeneratorService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isGenerating = false;
  bool _reportGenerated = false;
  String _reportContent = "";
  String _userName = "User";
  // Health inputs - Initialize from shared provider
  late double _bmi;
  late int _dailySteps;
  late double _sleepHours;
  late double _heartRisk;
  late int _stressScore;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    // Load data from shared health data provider and clamp to valid slider ranges
    _bmi = healthDataProvider.bmi.clamp(15.0, 40.0);
    _dailySteps = healthDataProvider.steps.clamp(0, 20000);
    _sleepHours = healthDataProvider.sleepHours.clamp(0.0, 12.0);
    _heartRisk = healthDataProvider.heartRisk.clamp(0.0, 100.0);
    _stressScore = healthDataProvider.stressScore.clamp(0, 100);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _reportGenerated = false;
    });

    // Generate report
    final report = await _reportService.generateTextReport(
      userName: _userName,
      bmi: _bmi,
      dailySteps: _dailySteps,
      sleepHours: _sleepHours,
      heartRisk: _heartRisk,
      stressScore: _stressScore,
    );

    setState(() {
      _reportContent = report;
      _isGenerating = false;
      _reportGenerated = true;
    });

    _animationController.forward(from: 0);
  }

  Future<void> _shareReport() async {
    await _reportService.saveAndShareReport(
      reportContent: _reportContent,
      fileName: 'health_report_${DateTime.now().millisecondsSinceEpoch}',
    );
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
                      _buildInfoCard(width),
                      SizedBox(height: width * 0.04),
                      _buildInputsCard(width),
                      SizedBox(height: width * 0.04),
                      _buildGenerateButton(width),
                      SizedBox(height: width * 0.04),
                      if (_reportGenerated) FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildReportPreview(width),
                      ),
                      SizedBox(height: width * 0.04),
                      _buildFeaturesCard(width),
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
                          colors: [Colors.green, Colors.teal],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Health Report Generator',
                      style: TextStyle(color: Colors.white, fontSize: width * 0.045, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge("📄 PDF Ready", Colors.green),
                    SizedBox(width: 8),
                    _buildBadge("📤 Shareable", Colors.blue),
                    SizedBox(width: 8),
                    _buildBadge("⚡ Advanced", Colors.cyan),
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
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.info_outline, color: Colors.green, size: width * 0.06),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comprehensive Health Report",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Generate detailed PDF reports with your vital signs and personalized recommendations.",
                  style: TextStyle(color: Colors.green.shade200, fontSize: width * 0.028),
                ),
              ],
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
                child: Icon(Icons.person, color: Colors.cyan, size: 18),
              ),
              SizedBox(width: 12),
              Text(
                "Patient Information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              onChanged: (v) => _userName = v.isEmpty ? "User" : v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Your Name",
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.badge, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(height: width * 0.04),
          _buildSlider("BMI", _bmi, 15, 40, (v) => setState(() => _bmi = v), "%.1f"),
          _buildSlider("Daily Steps", _dailySteps.toDouble(), 0, 20000, (v) => setState(() => _dailySteps = v.round()), "%.0f"),
          _buildSlider("Sleep (hrs)", _sleepHours, 0, 12, (v) => setState(() => _sleepHours = v), "%.1f"),
          _buildSlider("Heart Risk %", _heartRisk, 0, 100, (v) => setState(() => _heartRisk = v), "%.0f"),
          _buildSlider("Stress %", _stressScore.toDouble(), 0, 100, (v) => setState(() => _stressScore = v.round()), "%.0f"),
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                format == "%.0f" ? "${value.round()}" : value.toStringAsFixed(format == "%.1f" ? 1 : 0),
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.green,
            overlayColor: Colors.green.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(double width) {
    return GestureDetector(
      onTap: _isGenerating ? null : _generateReport,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
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
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              _isGenerating ? "Generating Report..." : "Generate Advanced Report",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width * 0.04),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Health Report",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Generated on ${_formatDate(DateTime.now())}",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.025,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        "Ready",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: width * 0.04),
          
          // Patient Info Card
          Container(
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 25,
                  child: Icon(Icons.person, color: Colors.blue.shade700, size: 28),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Patient Report",
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: width * 0.028,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code, color: Colors.green.shade700, size: 24),
                ),
              ],
            ),
          ),
          
          SizedBox(height: width * 0.04),
          
          // Health Metrics Grid
          Text(
            "Vital Signs",
            style: TextStyle(
              color: const Color(0xFF1a1a2e),
              fontSize: width * 0.035,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.025),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "BMI",
                  _bmi.toStringAsFixed(1),
                  _getBMIColor(_bmi),
                  Icons.monitor_weight,
                ),
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: _buildMetricCard(
                  "Steps",
                  _dailySteps.toString(),
                  Colors.orange,
                  Icons.directions_walk,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.025),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Sleep",
                  "${_sleepHours.toStringAsFixed(1)} hrs",
                  Colors.purple,
                  Icons.bedtime,
                ),
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: _buildMetricCard(
                  "Heart Risk",
                  "${_heartRisk.toStringAsFixed(0)}%",
                  _getHeartRiskColor(_heartRisk),
                  Icons.favorite,
                ),
              ),
            ],
          ),
          
          SizedBox(height: width * 0.04),
          
          // Report Content with styling
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.white],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: Colors.green.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Analysis Summary",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: width * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: width * 0.025),
                Text(
                  _reportContent,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: width * 0.028,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: width * 0.04),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _shareReport,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.035),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Share Report",
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.032,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: GestureDetector(
                  onTap: _shareReport,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.035),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Icon(Icons.download, color: Colors.blue.shade700, size: 24),
                  ),
                ),
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: GestureDetector(
                  onTap: _shareReport,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.035),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Icon(Icons.print, color: Colors.orange.shade700, size: 24),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: width * 0.03),
          
          // Footer
          Center(
            child: Text(
              "AI Health Guardian - Your Personal Health Assistant",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: width * 0.022,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: width * 0.024,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHeartRiskColor(double risk) {
    if (risk < 20) return Colors.green;
    if (risk < 40) return Colors.orange;
    if (risk < 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildFeaturesCard(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.amber, size: width * 0.05),
              ),
              SizedBox(width: 12),
              Text(
                "Advanced Report Features",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          _buildFeatureItem(Icons.analytics, "Comprehensive health analysis"),
          _buildFeatureItem(Icons.timeline, "Historical trend tracking"),
          _buildFeatureItem(Icons.recommend, "AI-powered recommendations"),
          _buildFeatureItem(Icons.picture_as_pdf, "PDF export & sharing"),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: Colors.amber.shade200, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
