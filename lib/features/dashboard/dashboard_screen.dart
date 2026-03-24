import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/glass_card.dart';
import 'widgets/health_score_card.dart';
import '../camera/camera_screen.dart';
import '../chatbot/chat_screen.dart';
import '../scanner/medicine_scanner.dart';
import '../hospitals/map_screen.dart';
import '../symptom_checker/symptom_checker_screen.dart';
import '../heart_risk/heart_risk_screen.dart';
import '../emergency/emergency_screen.dart';
import '../wellness_tips/wellness_tips_screen.dart';
import '../profile/user_profile_screen.dart';
import '../stress_detection/stress_detection_screen.dart';
import '../ai_insight/ai_health_insight_screen.dart';
import '../heart_rate/heart_rate_screen.dart';
import '../step_counter/step_counter_screen.dart';
import '../risk_prediction/risk_prediction_screen.dart';
import '../health_report/health_report_screen.dart';
import '../../widgets/health_charts.dart';
import '../../services/health_data_provider.dart';
import '../../services/location_share_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showCharts = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh health data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  void _toggleCharts() {
    setState(() {
      _showCharts = !_showCharts;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            // Beautiful animated gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                    Color(0xFF6B8DD6),
                  ],
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -height * 0.15,
              right: -width * 0.2,
              child: Container(
                width: width * 0.7,
                height: width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -height * 0.1,
              left: -width * 0.15,
              child: Container(
                width: width * 0.5,
                height: width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                  vertical: height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with user info
                    Row(
                      children: [
                        // Profile Avatar
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(width * 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: width * 0.08,
                              color: const Color(0xFF667eea),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Your Health Journey",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.035),

                    // Main Title with badges
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(width * 0.04),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "AI Health Guardian",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: width * 0.03),
                          // AI powered + Real-time + Mobile-first badges (clickable)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildClickableBadge("🤖 AI Powered", Colors.purple, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                                }),
                                SizedBox(width: width * 0.02),
                                _buildClickableBadge("⚡ Real-time", Colors.orange, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HeartRiskScreen()));
                                }),
                                SizedBox(width: width * 0.02),
                                _buildClickableBadge("📱 Mobile-first", Colors.green, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()));
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: height * 0.03),

                    // Toggle Charts Button
                    GestureDetector(
                      onTap: _toggleCharts,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: width * 0.025,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withOpacity(0.3),
                              Colors.blue.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(width * 0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showCharts ? Icons.visibility_off : Icons.insights,
                              color: Colors.white,
                              size: width * 0.05,
                            ),
                            SizedBox(width: width * 0.02),
                            Text(
                              _showCharts ? "Hide Health Trends" : "View Health Trends",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.035,
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            Icon(
                              _showCharts ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                              size: width * 0.04,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Health Charts Section - Using real-time data from healthDataProvider
                    if (_showCharts) ...[
                      SizedBox(height: height * 0.03),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: HealthCharts(
                          heartRiskData: healthDataProvider.heartRiskHistory,
                          bmiData: healthDataProvider.bmiHistory,
                          weeklyStepsData: healthDataProvider.stepsHistory,
                          weeklySleepData: healthDataProvider.sleepHistory,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                    ],

                    // Health Score Card - Using shared health data
                    HealthScoreCard(
                      bmi: healthDataProvider.bmi,
                      heartRisk: healthDataProvider.heartRisk,
                      sleepHours: healthDataProvider.sleepHours,
                      steps: healthDataProvider.steps,
                    ),

                    SizedBox(height: height * 0.025),

                    // Quick Stats Card
                    Container(
                      padding: EdgeInsets.all(width * 0.045),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(width * 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Stats",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard("BMI", healthDataProvider.bmi.toStringAsFixed(1), Colors.cyan, Icons.monitor_weight),
                              _buildStatCard("Heart Rate", "${healthDataProvider.heartRate.toStringAsFixed(0)} BPM", Colors.red, Icons.favorite),
                              _buildStatCard("Steps", "${healthDataProvider.steps}", Colors.green, Icons.directions_walk),
                            ],
                          ),
                          SizedBox(height: height * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard("Sleep", "${healthDataProvider.sleepHours.toStringAsFixed(1)}h", Colors.purple, Icons.bedtime),
                              _buildStatCard("Heart Risk", "${healthDataProvider.heartRisk.toStringAsFixed(0)}%", Colors.orange, Icons.warning_amber),
                              _buildStatCard("Stress", "${healthDataProvider.stressScore}", Colors.indigo, Icons.psychology),
                            ],
                          ),
                        ],
                      ),
                    ),


                    SizedBox(height: height * 0.025),

                    // Daily Wellness Tips Card
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WellnessTipsScreen()),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.045),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(width * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(width * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(width * 0.035),
                              ),
                              child: const Icon(
                                Icons.tips_and_updates,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: width * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Daily Wellness Tips",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tap to explore expert health advice",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(width * 0.025),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(width * 0.025),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.03),

                    // Services Section Title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Premium Health Tools",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    // Premium Health Tools Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: width * 0.035,
                      mainAxisSpacing: width * 0.035,
                      childAspectRatio: 1.0,
                      children: [
                        _buildServiceCard(
                          context,
                          "Share Location",
                          Icons.share_location,
                          "Share via WhatsApp",
                          const Color(0xFF25D366),
                          () => _showShareLocationSheet(context),
                        ),
                        _buildServiceCard(
                          context,
                          "Risk Prediction",
                          Icons.trending_up,
                          "Future health risks",
                          Colors.amber,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RiskPredictionScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Health Report",
                          Icons.description,
                          "Generate PDF reports",
                          Colors.green,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HealthReportScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "AI Chatbot",
                          Icons.chat_bubble_rounded,
                          "24/7 health assistant",
                          Colors.blue,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ChatScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Hospitals",
                          Icons.local_hospital,
                          "Find medical help",
                          Colors.red,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MapScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Stress Detection",
                          Icons.psychology,
                          "Monitor stress levels",
                          Colors.indigo,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const StressDetectionScreen())),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.03),

                    // Original Services Section
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Other Services",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    // Original Services Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: width * 0.035,
                      mainAxisSpacing: width * 0.035,
                      childAspectRatio: 1.0,
                      children: [
                        _buildServiceCard(
                          context,
                          "Camera Diagnosis",
                          Icons.camera_alt,
                          "AI skin analysis",
                          const Color(0xFF667eea),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CameraScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Med Scanner",
                          Icons.document_scanner,
                          "Medication info",
                          Colors.green,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MedicineScanner())),
                        ),
                        _buildServiceCard(
                          context,
                          "Symptom Check",
                          Icons.health_and_safety,
                          "Check symptoms",
                          Colors.orange,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SymptomCheckerScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Heart Risk",
                          Icons.favorite,
                          "Heart health analysis",
                          Colors.pink,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HeartRiskScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Emergency",
                          Icons.warning_rounded,
                          "Quick emergency help",
                          Colors.redAccent,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EmergencyScreen())),
                        ),
                        _buildServiceCard(
                          context,
                          "Step Counter",
                          Icons.directions_walk,
                          "Track daily steps",
                          Colors.teal,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const StepCounterScreen())),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableBadge(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    double width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.045),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(width * 0.035),
              ),
              child: Icon(
                icon,
                size: width * 0.085,
                color: color,
              ),
            ),
            SizedBox(height: width * 0.025),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1a1a2e),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: width * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Show the share location bottom sheet
  void _showShareLocationSheet(BuildContext context) async {
    final contacts = await LocationShareService.showContactSelectionDialog(context);
    if (contacts != null && contacts.isNotEmpty && mounted) {
      // Get location and share via WhatsApp
      final location = await LocationShareService.getCurrentLocation();
      if (location != null) {
        await LocationShareService.shareLocationViaWhatsApp(contacts, location);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location. Please check location permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}


