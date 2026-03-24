import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/health_service.dart';
import '../../core/constants/colors.dart';

class SmartHealthScreen extends StatefulWidget {
  const SmartHealthScreen({super.key});

  @override
  State<SmartHealthScreen> createState() => _SmartHealthScreenState();
}

class _SmartHealthScreenState extends State<SmartHealthScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _heartRateController = TextEditingController(text: '72');
  final TextEditingController _systolicController = TextEditingController(text: '120');
  final TextEditingController _diastolicController = TextEditingController(text: '80');
  final TextEditingController _spO2Controller = TextEditingController(text: '98');
  final TextEditingController _temperatureController = TextEditingController(text: '36.6');
  final TextEditingController _stepsController = TextEditingController(text: '8000');
  final TextEditingController _sleepController = TextEditingController(text: '7.5');
  final TextEditingController _waterController = TextEditingController(text: '1.5');

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _refreshController;

  // State
  bool _isDarkMode = true;
  String _selectedFoodType = 'Mixed';
  String _dailyTip = '🌟 Great job! Keep up your healthy habits today!';

  // Calculated values
  int _healthScore = 85;
  double _heartRisk = 15.0;
  String _stressLevel = 'Low';
  int _caloriesBurned = 320;
  String _mood = '😊';
  String _sleepQuality = 'Good';
  List<String> _warnings = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _calculateAllMetrics();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _spO2Controller.dispose();
    _temperatureController.dispose();
    _stepsController.dispose();
    _sleepController.dispose();
    _waterController.dispose();
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _calculateAllMetrics() {
    setState(() {
      final heartRate = int.tryParse(_heartRateController.text) ?? 72;
      final systolic = int.tryParse(_systolicController.text) ?? 120;
      final diastolic = int.tryParse(_diastolicController.text) ?? 80;
      final spO2 = double.tryParse(_spO2Controller.text) ?? 98;
      final temperature = double.tryParse(_temperatureController.text) ?? 36.6;
      final steps = int.tryParse(_stepsController.text) ?? 8000;
      final sleepHours = double.tryParse(_sleepController.text) ?? 7.5;
      final water = double.tryParse(_waterController.text) ?? 1.5;

      // Calculate BMI from stored data or default
      final bmi = 24.0; // Would come from health data

      // Calculate heart risk
      _heartRisk = HealthService.calculateHeartRisk(
        age: 30,
        bmi: bmi,
        sleepHours: sleepHours,
        steps: steps,
        bloodPressureSystolic: systolic,
      );

      // Calculate health score
      _healthScore = HealthService.calculateHealthScore(
        bmi: bmi,
        heartRate: heartRate,
        spO2: spO2,
        temperature: temperature,
        steps: steps,
        sleepHours: sleepHours,
        heartRisk: _heartRisk,
      );

      // Calculate stress level
      _stressLevel = HealthService.getStressLevel(
        heartRate: heartRate,
        sleepHours: sleepHours,
        steps: steps,
      );

      // Calculate calories
      _caloriesBurned = HealthService.calculateCaloriesBurned(steps);

      // Get mood
      _mood = HealthService.getMood(
        healthScore: _healthScore,
        stressLevel: _stressLevel,
      );

      // Get sleep quality
      _sleepQuality = sleepHours >= 7 ? 'Good' : 'Poor';

      // Get health warnings
      _warnings = HealthService.getHealthWarnings(
        heartRate: heartRate,
        bloodPressureSystolic: systolic,
        bloodPressureDiastolic: diastolic,
        spO2: spO2,
        temperature: temperature,
      );

      // Generate daily tip
      _dailyTip = HealthService.generateHealthTip(
        steps: steps,
        waterIntake: water,
        sleepHours: sleepHours,
        calories: _caloriesBurned,
        stressLevel: _stressLevel,
      );
    });
  }

  Color get _backgroundColor => _isDarkMode
      ? const Color(0xFF0a0a1a)
      : const Color(0xFFF5F5F5);

  Color get _cardColor => _isDarkMode
      ? Colors.white.withOpacity(0.1)
      : Colors.white.withOpacity(0.9);

  Color get _textColor => _isDarkMode ? Colors.white : const Color(0xFF1a1a2e);

  Color get _subtitleColor => _isDarkMode
      ? Colors.white60
      : Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: _isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                    Color(0xFF1a1a2e),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey.shade100,
                  ],
                ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(width),

              // Content
              SliverPadding(
                padding: EdgeInsets.all(width * 0.04),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // AI Health Score Card
                    _buildHealthScoreCard(width),
                    SizedBox(height: width * 0.04),

                    // Emergency Buttons
                    _buildEmergencySection(width),
                    SizedBox(height: width * 0.04),

                    // Core Health Metrics
                    _buildSectionTitle('Vital Signs', Icons.favorite, Colors.red),
                    SizedBox(height: width * 0.03),
                    _buildCoreMetricsGrid(width),
                    SizedBox(height: width * 0.04),

                    // Intermediate Features
                    _buildSectionTitle('Daily Tracking', Icons.trending_up, Colors.cyan),
                    SizedBox(height: width * 0.03),
                    _buildIntermediateSection(width),
                    SizedBox(height: width * 0.04),

                    // Stress & Mood
                    _buildSectionTitle('Mental Wellness', Icons.psychology, Colors.purple),
                    SizedBox(height: width * 0.03),
                    _buildStressMoodSection(width),
                    SizedBox(height: width * 0.04),

                    // Health Tips
                    _buildDailyTipsCard(width),
                    SizedBox(height: width * 0.04),

                    // Health Warnings
                    if (_warnings.isNotEmpty) ...[
                      _buildWarningsCard(width),
                      SizedBox(height: width * 0.04),
                    ],

                    // Update Button
                    _buildUpdateButton(width),
                    SizedBox(height: width * 0.1),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(double width) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: width * 0.15,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Smart Health Monitor',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.bold,
          fontSize: width * 0.05,
        ),
      ),
      actions: [
        // Dark/Light Mode Toggle
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: _textColor,
          ),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        SizedBox(width: width * 0.02),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: _textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, double? padding}) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(padding ?? width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardColor,
            _cardColor.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHealthScoreCard(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF667eea), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Health Score',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(_mood, style: const TextStyle(fontSize: 32)),
            ],
          ),
          SizedBox(height: width * 0.05),

          // Score Circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: width * 0.35,
                  height: width * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(HealthService.getHealthScoreColor(_healthScore))
                            .withOpacity(0.3),
                        Color(HealthService.getHealthScoreColor(_healthScore))
                            .withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Color(HealthService.getHealthScoreColor(_healthScore)),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(HealthService.getHealthScoreColor(_healthScore))
                            .withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_healthScore',
                        style: TextStyle(
                          color: Color(HealthService.getHealthScoreColor(_healthScore)),
                          fontSize: width * 0.12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of 100',
                        style: TextStyle(
                          color: _subtitleColor,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.04),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Color(HealthService.getHealthScoreColor(_healthScore)),
              borderRadius: BorderRadius.circular(width * 0.08),
            ),
            child: Text(
              HealthService.getHealthScoreStatus(_healthScore),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: width * 0.04),

          // Risk Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('Heart Risk', '${_heartRisk.toStringAsFixed(1)}%', _getRiskColor()),
              Container(width: 1, height: 40, color: _subtitleColor.withOpacity(0.3)),
              _buildMiniStat('Stress', _stressLevel, _getStressColor()),
              Container(width: 1, height: 40, color: _subtitleColor.withOpacity(0.3)),
              _buildMiniStat('Calories', '$_caloriesBurned', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _subtitleColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor() {
    if (_heartRisk < 15) return Colors.green;
    if (_heartRisk < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getStressColor() {
    switch (_stressLevel) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmergencySection(double width) {
    return Row(
      children: [
        // Emergency Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              _showEmergencyDialog();
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF512F).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 24),
                  SizedBox(width: width * 0.02),
                  const Text(
                    'Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        // Nearby Hospitals
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening nearby hospitals...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFF11998e),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF11998e).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                  SizedBox(width: width * 0.02),
                  const Text(
                    'Hospitals',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoreMetricsGrid(double width) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildHeartRateCard(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildBloodPressureCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        Row(
          children: [
            Expanded(child: _buildSpO2Card(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildTemperatureCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        _buildStepsCard(width),
      ],
    );
  }

  Widget _buildHeartRateCard(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            _heartRateController.text.isEmpty ? '--' : _heartRateController.text,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'BPM',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _heartRateController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Update',
              hintStyle: TextStyle(color: _subtitleColor, fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _calculateAllMetrics(),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.speed, color: Colors.pink, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            '${_systolicController.text}/${_diastolicController.text}',
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'mmHg',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                child: TextField(
                  controller: _systolicController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor, fontSize: 10),
                  decoration: InputDecoration(
                    hintText: 'Sys',
                    hintStyle: TextStyle(color: _subtitleColor, fontSize: 8),
                    contentPadding: const EdgeInsets.all(4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onChanged: (_) => _calculateAllMetrics(),
                ),
              ),
              const Text(' / ', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 40,
                child: TextField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor, fontSize: 10),
                  decoration: InputDecoration(
                    hintText: 'Dia',
                    hintStyle: TextStyle(color: _subtitleColor, fontSize: 8),
                    contentPadding: const EdgeInsets.all(4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onChanged: (_) => _calculateAllMetrics(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpO2Card(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.air, color: Colors.blue, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            _spO2Controller.text.isEmpty ? '--' : _spO2Controller.text,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '% SpO2',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _spO2Controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Update',
              hintStyle: TextStyle(color: _subtitleColor, fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _calculateAllMetrics(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thermostat, color: Colors.orange, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            _temperatureController.text.isEmpty ? '--' : _temperatureController.text,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '°C',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          TextField(
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: _textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Update',
              hintStyle: TextStyle(color: _subtitleColor, fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _calculateAllMetrics(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(double width) {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk, color: Colors.green, size: 28),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepsController.text.isEmpty ? '--' : _stepsController.text,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Steps Today',
                  style: TextStyle(color: _subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: _textColor, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Update',
                hintStyle: TextStyle(color: _subtitleColor, fontSize: 10),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (_) => _calculateAllMetrics(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntermediateSection(double width) {
    return Column(
      children: [
        // Sleep & Water Row
        Row(
          children: [
            Expanded(child: _buildSleepCard(width)),
            SizedBox(width: width * 0.03),
            Expanded(child: _buildWaterCard(width)),
          ],
        ),
        SizedBox(height: width * 0.03),
        // Food Type Detection
        _buildFoodCard(width),
      ],
    );
  }

  Widget _buildSleepCard(double width) {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bedtime, color: Colors.purple, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            _sleepController.text.isEmpty ? '--' : _sleepController.text,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Hours Sleep',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _sleepQuality == 'Good'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _sleepQuality,
              style: TextStyle(
                color: _sleepQuality == 'Good' ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(double width) {
    final waterGoal = 2.0;
    final waterCurrent = double.tryParse(_waterController.text) ?? 0;
    final progress = (waterCurrent / waterGoal).clamp(0.0, 1.0);

    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.cyan, size: 28),
          ),
          SizedBox(height: width * 0.02),
          Text(
            '${_waterController.text}L',
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'of ${waterGoal}L',
            style: TextStyle(color: _subtitleColor, fontSize: 12),
          ),
          SizedBox(height: width * 0.02),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _subtitleColor.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.cyan),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(double width) {
    final suggestion = HealthService.getFoodSuggestion(_selectedFoodType);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Type',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'What did you eat today?',
                      style: TextStyle(color: _subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _subtitleColor.withOpacity(0.3)),
            ),
            child: DropdownButton<String>(
              value: _selectedFoodType,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: _isDarkMode ? const Color(0xFF1a1a2e) : Colors.white,
              style: TextStyle(color: _textColor),
              items: ['Junk', 'Healthy', 'Mixed'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFoodType = value ?? 'Mixed';
                });
                _calculateAllMetrics();
              },
            ),
          ),
          SizedBox(height: width * 0.03),
          // Suggestion
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF667eea), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressMoodSection(double width) {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Stress Level
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStressColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stressLevel == 'High'
                      ? Icons.sentiment_very_dissatisfied
                      : _stressLevel == 'Medium'
                          ? Icons.sentiment_neutral
                          : Icons.sentiment_very_satisfied,
                  color: _getStressColor(),
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stress Level',
                style: TextStyle(color: _subtitleColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _stressLevel,
                style: TextStyle(
                  color: _getStressColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 80, color: _subtitleColor.withOpacity(0.3)),
          // Mood
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(_mood, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              Text(
                'Mood',
                style: TextStyle(color: _subtitleColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _healthScore >= 70 ? 'Happy' : _healthScore >= 50 ? 'Neutral' : 'Concerned',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipsCard(double width) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates, color: Color(0xFF667eea), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Health Tip',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.2),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF667eea), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dailyTip,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsCard(double width) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Health Warnings',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          ...(_warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          warning,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(double width) {
    return ElevatedButton.icon(
      onPressed: () {
        _refreshController.forward(from: 0);
        _calculateAllMetrics();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health data updated!'),
            backgroundColor: Color(0xFF667eea),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: RotationTransition(
        turns: _refreshController,
        child: const Icon(Icons.refresh),
      ),
      label: const Text(
        'Update Data',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: width * 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1a1a2e) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Emergency Alert',
              style: TextStyle(color: _textColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.phone, color: Colors.red, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Calling emergency contact...',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please stay calm. Help is on the way.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency services contacted!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
