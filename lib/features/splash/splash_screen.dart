import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/responsive.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../health_input/health_input_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final hasHealthData = await _checkUserHasHealthData(user.id);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasHealthData ? const DashboardScreen() : const HealthInputScreen(),
      ),
    );
  }

  Future<bool> _checkUserHasHealthData(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .limit(1);
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B3B3B),
              Color(0xFF0F766E),
              Color(0xFF22C55E),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(size: isDesktop ? 360 : 240, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: -140,
              left: -60,
              child: _GlowOrb(size: isDesktop ? 320 : 220, color: Colors.white.withValues(alpha: 0.08)),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
                  child: Padding(
                    padding: Responsive.pagePadding(context),
                    child: isDesktop
                        ? Row(
                            children: [
                              Expanded(child: _buildIntro(context)),
                              const SizedBox(width: 32),
                              SizedBox(width: 420, child: _buildLoaderCard(context)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildIntro(context),
                              const SizedBox(height: 28),
                              _buildLoaderCard(context),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Text(
            "Responsive health intelligence",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "AI Health Guardian",
          style: theme.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: Responsive.isDesktop(context) ? 56 : 38,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "A cleaner web experience for monitoring risk, wellness, activity, and day-to-day health insights.",
          style: theme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SplashChip(label: "Heart risk"),
            _SplashChip(label: "BMI tracking"),
            _SplashChip(label: "Stress insights"),
            _SplashChip(label: "Reports"),
          ],
        ),
      ],
    );
  }

  Widget _buildLoaderCard(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            "Preparing your workspace",
            textAlign: TextAlign.center,
            style: theme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            "Checking your account, syncing health data, and loading the dashboard.",
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SplashChip extends StatelessWidget {
  final String label;

  const _SplashChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
