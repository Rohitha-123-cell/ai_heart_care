import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../core/constants/colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../../services/health_data_service.dart';
import '../auth/logout_screen.dart';
import '../chatbot/chat_screen.dart';
import '../symptom_checker/symptom_checker_screen.dart';
import '../heart_risk/heart_risk_screen.dart';
import '../emergency/emergency_screen.dart';
import '../camera/camera_screen.dart';
import '../scanner/medicine_scanner.dart';
import '../wellness_tips/wellness_tips_screen.dart';
import '../ai_insight/ai_health_insight_screen.dart';
import '../smart_health/smart_health_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthService _authService = AuthService();

  String _userName = 'User';
  String _userEmail = 'user@email.com';

  // Real health data from Supabase
  double _bmi = 24.5;
  double _heartRisk = 35.0;
  double _sleepHours = 7.5;
  int _steps = 8500;
  double _healthScore = 87;
  bool _isLoading = true;

  // Smart watch style health metrics
  List<Map<String, dynamic>> _healthMetrics = [];

  // Hackathon impressive features with navigation
  final List<Map<String, dynamic>> _hackathonFeatures = [
    {'icon': Icons.medical_services, 'title': 'Smart Health Monitor', 'subtitle': 'All-in-one health dashboard', 'color': Colors.deepPurple, 'screen': const SmartHealthScreen()},
    {'icon': Icons.auto_awesome, 'title': 'AI Health Insight', 'subtitle': 'Combined AI analysis', 'color': Colors.blue, 'screen': const AIHealthInsightScreen()},
    {'icon': Icons.psychology, 'title': 'AI Health Prediction', 'subtitle': 'ML-based disease risk analysis', 'color': Colors.indigo, 'screen': const HeartRiskScreen()},
    {'icon': Icons.emergency, 'title': 'Emergency AI Dispatch', 'subtitle': 'Auto-detect & alert nearest hospital', 'color': Colors.red, 'screen': const EmergencyScreen()},
    {'icon': Icons.coronavirus, 'title': 'Symptom Scanner', 'subtitle': 'AI-powered symptom analysis', 'color': Colors.teal, 'screen': const SymptomCheckerScreen()},
    {'icon': Icons.medication, 'title': 'Medicine Interaction', 'subtitle': 'Check drug compatibility', 'color': Colors.amber, 'screen': const MedicineScanner()},
    {'icon': Icons.timeline, 'title': 'Health Timeline', 'subtitle': 'Track your health journey', 'color': Colors.deepPurple, 'screen': const WellnessTipsScreen()},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    _loadUserData();
    _loadHealthData();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? 'user@email.com';
        // Extract name from email (before @)
        _userName = _userEmail.split('@').first;
        // Capitalize first letter
        _userName = _userName.isNotEmpty 
            ? _userName[0].toUpperCase() + _userName.substring(1)
            : 'User';
      });
    }
  }

  Future<void> _loadHealthData() async {
    try {
      final healthData = await HealthDataService.getLatestHealthData();
      if (healthData != null && mounted) {
        setState(() {
          _bmi = (healthData['bmi'] as num?)?.toDouble() ?? 24.5;
          _heartRisk = (healthData['heart_risk'] as num?)?.toDouble() ?? 35.0;
          _sleepHours = (healthData['sleep_hours'] as num?)?.toDouble() ?? 7.5;
          _steps = (healthData['steps'] as int?) ?? 8500;
          _calculateHealthScore();
          _updateHealthMetrics();
          _isLoading = false;
        });
      } else {
        // Save default health data for new users
        await _saveHealthData();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _updateHealthMetrics();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateHealthMetrics();
        });
      }
    }
  }

  Future<void> _saveHealthData() async {
    try {
      await HealthDataService.saveHealthData(
        bmi: _bmi,
        heartRisk: _heartRisk,
        sleepHours: _sleepHours,
        steps: _steps,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  void _calculateHealthScore() {
    // Calculate overall health score based on metrics
    double bmiScore = (_bmi >= 18.5 && _bmi <= 24.9) ? 100 : 
                      (_bmi >= 25 && _bmi <= 29.9) ? 70 : 50;
    double sleepScore = (_sleepHours >= 7 && _sleepHours <= 9) ? 100 :
                        (_sleepHours >= 6) ? 80 : 60;
    double activityScore = (_steps >= 10000) ? 100 :
                          (_steps >= 5000) ? 70 : 40;
    double heartScore = 100 - _heartRisk;
    
    _healthScore = (bmiScore + sleepScore + activityScore + heartScore) / 4;
  }

  void _updateHealthMetrics() {
    setState(() {
      _healthMetrics = [
        {'icon': Icons.bedtime, 'label': 'Sleep', 'value': '${_sleepHours}h', 'unit': 'hours', 'color': Colors.purple, 'progress': _sleepHours / 9},
        {'icon': Icons.directions_walk, 'label': 'Steps', 'value': _steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'), 'unit': 'steps', 'color': Colors.green, 'progress': _steps / 10000},
        {'icon': Icons.favorite, 'label': 'Heart Rate', 'value': '${(65 + (_steps % 20)).toInt()}', 'unit': 'bpm', 'color': Colors.red, 'progress': 0.85},
        {'icon': Icons.local_fire_department, 'label': 'Calories', 'value': '${(1800 + (_steps * 0.04)).toInt()}', 'unit': 'kcal', 'color': Colors.orange, 'progress': 0.8},
        {'icon': Icons.water_drop, 'label': 'Water', 'value': '1.8', 'unit': 'L', 'color': Colors.cyan, 'progress': 0.72},
        {'icon': Icons.air, 'label': 'SpO2', 'value': '98', 'unit': '%', 'color': Colors.blue, 'progress': 0.98},
      ];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
              ),
            ),

            // Floating shapes
            Positioned(
              top: -width * 0.2,
              right: -width * 0.1,
              child: Container(
                width: width * 0.6,
                height: width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // App Bar
                          _buildAppBar(width),

                          // Profile Header
                          _buildProfileHeader(width, height),

                          // Smart Watch Health Ring
                          _buildSmartWatchRing(width, height),

                          // Health Metrics Grid
                          _buildHealthMetrics(width, height),

                          // Hackathon Features
                          _buildHackathonFeatures(width, height),

                          // Logout Button
                          _buildLogoutButton(width, height),

                          SizedBox(height: height * 0.05),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double width) {
    return Padding(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: width * 0.06,
            ),
          ),
          Expanded(
            child: Text(
              "My Profile",
              style: TextStyle(
                fontSize: width * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: width * 0.1), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileHeader(double width, double height) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.secondary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Avatar with glow
          Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName.substring(0, 1).toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: width * 0.08,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: width * 0.028,
                    color: Colors.white60,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartWatchRing(double width, double height) {
    return Container(
      margin: EdgeInsets.all(width * 0.04),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health Overview",
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      "+12%",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),

          // Animated Circular Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Main score ring
              _buildCircularRing(
                width: width * 0.32,
                progress: _healthScore / 100,
                color: Colors.cyan,
                centerWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${_healthScore.toInt()}",
                      style: TextStyle(
                        fontSize: width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Health",
                      style: TextStyle(
                        fontSize: width * 0.022,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini stats
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniStat("BMI", _bmi.toStringAsFixed(1), Colors.blue),
                  SizedBox(height: height * 0.01),
                  _buildMiniStat("Sleep", "${_sleepHours}h", Colors.purple),
                  SizedBox(height: height * 0.01),
                  _buildMiniStat("Steps", _steps.toString(), Colors.green),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularRing({
    required double width,
    required double progress,
    required Color color,
    required Widget centerWidget,
  }) {
    return SizedBox(
      width: width,
      height: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(width, width),
            painter: _RingPainter(
              progress: 1.0,
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 10,
            ),
          ),
          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(width, width),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  strokeWidth: 10,
                ),
              );
            },
          ),
          // Center content
          centerWidget,
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics(double width, double height) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Activity",
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: height * 0.015),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: width * 0.025,
              mainAxisSpacing: width * 0.025,
              childAspectRatio: 0.9,
            ),
            itemCount: _healthMetrics.length,
            itemBuilder: (context, index) {
              final metric = _healthMetrics[index];
              return _buildMetricCard(metric, width, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric, double width, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 100),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.018),
              decoration: BoxDecoration(
                color: (metric['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                metric['icon'] as IconData,
                color: metric['color'] as Color,
                size: width * 0.05,
              ),
            ),
            SizedBox(height: width * 0.015),
            Text(
              metric['value'] as String,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.03,
              ),
            ),
            Text(
              metric['unit'] as String,
              style: TextStyle(
                color: Colors.white60,
                fontSize: width * 0.018,
              ),
            ),
            SizedBox(height: width * 0.01),
            // Progress indicator
            SizedBox(
              width: width * 0.12,
              height: 3,
              child: LinearProgressIndicator(
                value: metric['progress'] as double,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: metric['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHackathonFeatures(double width, double height) {
    return Container(
      margin: EdgeInsets.all(width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: width * 0.035,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                "AI Features",
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),
          ...List.generate(_hackathonFeatures.length, (index) {
            final feature = _hackathonFeatures[index];
            return _buildFeatureItem(feature, width, index);
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature, double width, int index) {
    Widget screen = feature['screen'] as Widget;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 100),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(50 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: width * 0.025),
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: feature['color'] as Color,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.032,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      feature['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: width * 0.024,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: width * 0.035,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogoutScreen()),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: height * 0.018),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: width * 0.045,
              ),
              SizedBox(width: width * 0.025),
              Text(
                "Logout",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
