import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/health_data_provider.dart';
import '../../services/location_share_service.dart';
import '../../widgets/health_charts.dart' hide GlassCard;
import '../ai_insight/ai_health_insight_screen.dart';
import '../camera/camera_screen.dart';
import '../chatbot/chat_screen.dart';
import '../dashboard/widgets/health_score_card.dart';
import '../disease_trends/disease_trend_dashboard_screen.dart';
import '../emergency/emergency_screen.dart';
import '../health_report/health_report_screen.dart';
import '../heart_rate/heart_rate_screen.dart';
import '../heart_risk/heart_risk_screen.dart';
import '../hospitals/map_screen.dart';
import '../menstrual_cycle/menstrual_cycle_screen.dart';

import '../profile/user_profile_screen.dart';
import '../risk_prediction/risk_prediction_screen.dart';
import '../scanner/medicine_scanner.dart';
import '../step_counter/step_counter_screen.dart';
import '../stress_detection/stress_detection_screen.dart';
import '../symptom_checker/symptom_checker_screen.dart';
import '../wellness_tips/wellness_tips_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _showCharts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF083344),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF031F24),
                Color(0xFF0B4F53),
                Color(0xFF0F766E),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -180,
                right: -120,
                child: _BackdropCircle(
                  size: isDesktop ? 480 : 280,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                bottom: -140,
                left: -80,
                child: _BackdropCircle(
                  size: isDesktop ? 360 : 220,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
                      child: SingleChildScrollView(
                        padding: Responsive.pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context),
                            const SizedBox(height: 24),
                            _buildHero(context),
                            const SizedBox(height: 20),
                            _buildStatsSection(context),
                            const SizedBox(height: 20),
                            if (_showCharts) ...[
                              _buildChartsCard(context),
                              const SizedBox(height: 20),
                            ],
                            _buildTipsBanner(context),
                            const SizedBox(height: 24),
                            _buildSection(context, "Premium Health Tools", _premiumTools(context)),
                            const SizedBox(height: 24),
                            _buildSection(context, "More Services", _coreTools(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Health workspace",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "AI Health Guardian",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: "Heart rate",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HeartRateScreen()),
          ),
          icon: const Icon(Icons.monitor_heart_outlined, color: Colors.white),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfileScreen()),
          ),
          icon: const Icon(Icons.person_outline_rounded),
          label: const Text("Profile"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F766E),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final heroStats = [
      _MetricCardData(
        title: "Health score",
        value: "${_overallScore().round()}%",
        subtitle: "Snapshot of your overall health balance",
        icon: Icons.favorite_rounded,
        color: const Color(0xFFF97316),
      ),
      _MetricCardData(
        title: "Daily steps",
        value: "${healthDataProvider.steps}",
        subtitle: "Movement tracked for today",
        icon: Icons.directions_walk_rounded,
        color: const Color(0xFF22C55E),
      ),
      _MetricCardData(
        title: "Sleep",
        value: "${healthDataProvider.sleepHours.toStringAsFixed(1)} h",
        subtitle: "Rest logged in your profile",
        icon: Icons.bedtime_outlined,
        color: const Color(0xFF60A5FA),
      ),
    ];

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: _buildHeroContent(context, heroStats),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: HealthScoreCard(
                  bmi: healthDataProvider.bmi,
                  heartRisk: healthDataProvider.heartRisk,
                  sleepHours: healthDataProvider.sleepHours,
                  steps: healthDataProvider.steps,
                ),
              ),
            ],
          )
        : Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: _buildHeroContent(context, heroStats),
              ),
              const SizedBox(height: 18),
              HealthScoreCard(
                bmi: healthDataProvider.bmi,
                heartRisk: healthDataProvider.heartRisk,
                sleepHours: healthDataProvider.sleepHours,
                steps: healthDataProvider.steps,
              ),
            ],
          );
  }

  Widget _buildHeroContent(BuildContext context, List<_MetricCardData> heroStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "Responsive dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "A cleaner health dashboard for desktop, tablet, and mobile.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Track your key health metrics, open tools quickly, and surface the most important next action without a crowded mobile-only layout.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _BadgeButton(
              label: "AI insight",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIHealthInsightScreen()),
              ),
            ),
            _BadgeButton(
              label: _showCharts ? "Hide trends" : "View trends",
              onTap: () => setState(() => _showCharts = !_showCharts),
            ),
            _BadgeButton(
              label: "Wellness tips",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WellnessTipsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: heroStats.map((item) => _MetricCard(item: item)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = [
      _MetricCardData(
        title: "BMI",
        value: healthDataProvider.bmi.toStringAsFixed(1),
        subtitle: "Current body mass index",
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFF06B6D4),
      ),
      _MetricCardData(
        title: "Heart rate",
        value: "${healthDataProvider.heartRate.toStringAsFixed(0)} BPM",
        subtitle: "Latest recorded pulse",
        icon: Icons.favorite_outline_rounded,
        color: const Color(0xFFEF4444),
      ),
      _MetricCardData(
        title: "Heart risk",
        value: "${healthDataProvider.heartRisk.toStringAsFixed(0)}%",
        subtitle: "Estimated cardiovascular risk",
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _MetricCardData(
        title: "Stress",
        value: "${healthDataProvider.stressScore}",
        subtitle: "Stress score summary",
        icon: Icons.psychology_alt_outlined,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today at a glance",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "A simplified overview designed to read clearly on larger screens.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 700
                      ? 2
                      : 1;
              final itemWidth = (constraints.maxWidth - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: stats
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _SummaryCard(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Health trends",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Historical insights for BMI, heart risk, movement, and sleep.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          HealthCharts(
            heartRiskData: healthDataProvider.heartRiskHistory,
            bmiData: healthDataProvider.bmiHistory,
            weeklyStepsData: healthDataProvider.stepsHistory,
            weeklySleepData: healthDataProvider.sleepHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBanner(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WellnessTipsScreen()),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF0EA5A4)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.tips_and_updates_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily wellness tips",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Open expert-backed suggestions for sleep, movement, food, and routine improvements.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<_ToolItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1200
                ? 3
                : constraints.maxWidth >= 760
                    ? 2
                    : 1;
            final itemWidth = (constraints.maxWidth - ((columns - 1) * 16)) / columns;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _ToolCard(item: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  List<_ToolItem> _premiumTools(BuildContext context) => [
        _ToolItem(
          title: "Share Location",
          subtitle: "Send your location through WhatsApp",
          icon: Icons.share_location_rounded,
          color: const Color(0xFF16A34A),
          onTap: () => _showShareLocationSheet(context),
        ),
        _ToolItem(
          title: "Risk Prediction",
          subtitle: "See future health risk patterns",
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFF97316),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiskPredictionScreen()),
          ),
        ),
        _ToolItem(
          title: "Health Report",
          subtitle: "Generate export-ready health reports",
          icon: Icons.description_outlined,
          color: const Color(0xFF0891B2),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthReportScreen()),
          ),
        ),
        _ToolItem(
          title: "AI Chatbot",
          subtitle: "Ask questions and get guided responses",
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF2563EB),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        ),
        _ToolItem(
          title: "Hospitals",
          subtitle: "Find nearby medical support quickly",
          icon: Icons.local_hospital_outlined,
          color: const Color(0xFFDC2626),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
        ),
        _ToolItem(
          title: "Disease Trends",
          subtitle: "Visualize disease spread patterns locally",
          icon: Icons.query_stats_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiseaseTrendDashboardScreen()),
          ),
        ),
        _ToolItem(
          title: "Stress Detection",
          subtitle: "Track mood and stress-related signals",
          icon: Icons.psychology_alt_outlined,
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StressDetectionScreen()),
          ),
        ),
        _ToolItem(
          title: "Menstrual Cycle",
          subtitle: "Track cycles, symptoms & predictions",
          icon: Icons.female_rounded,
          color: const Color(0xFFBE185D),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenstrualCycleScreen()),
          ),
        ),
      ];

  List<_ToolItem> _coreTools(BuildContext context) => [
        _ToolItem(
          title: "Camera Diagnosis",
          subtitle: "Use camera-based health analysis",
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFF0F766E),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          ),
        ),
        _ToolItem(
          title: "Medicine Scanner",
          subtitle: "Scan and review medication details",
          icon: Icons.document_scanner_outlined,
          color: const Color(0xFF16A34A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicineScanner()),
          ),
        ),
        _ToolItem(
          title: "Symptom Checker",
          subtitle: "Review symptoms with guided prompts",
          icon: Icons.health_and_safety_outlined,
          color: const Color(0xFFF97316),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
          ),
        ),
        _ToolItem(
          title: "Heart Risk",
          subtitle: "Monitor cardio-related risk markers",
          icon: Icons.favorite_outline_rounded,
          color: const Color(0xFFE11D48),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HeartRiskScreen()),
          ),
        ),
        _ToolItem(
          title: "Emergency",
          subtitle: "Get quick emergency support options",
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEF4444),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyScreen()),
          ),
        ),
        _ToolItem(
          title: "Step Counter",
          subtitle: "Track daily movement and progress",
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF0D9488),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StepCounterScreen()),
          ),
        ),
      ];

  double _overallScore() {
    final bmiScore =
        healthDataProvider.bmi >= 18.5 && healthDataProvider.bmi <= 24.9 ? 100.0 : 70.0;
    final heartScore = 100 - healthDataProvider.heartRisk;
    final sleepScore =
        healthDataProvider.sleepHours >= 7 && healthDataProvider.sleepHours <= 9 ? 100.0 : 70.0;
    final activityScore = healthDataProvider.steps >= 10000 ? 100.0 : 70.0;
    return (bmiScore + heartScore + sleepScore + activityScore) / 4;
  }

  Future<void> _showShareLocationSheet(BuildContext context) async {
    final contacts = await LocationShareService.showContactSelectionDialog(context);
    if (contacts == null || contacts.isEmpty || !mounted) return;

    final location = await LocationShareService.getCurrentLocation();
    if (location == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Please check location permissions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await LocationShareService.shareLocationViaWhatsApp(contacts, location);
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(item.subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _MetricCardData item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52606D),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolItem item;

  const _ToolCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    "Open tool",
                    style: TextStyle(color: item.color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: item.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BadgeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _BackdropCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
