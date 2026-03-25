import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/fingerprint_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../dashboard/dashboard_screen.dart';
import '../health_input/health_input_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FingerprintService _fingerprintService = FingerprintService();

  bool _isFingerprintAvailable = false;
  bool _isCheckingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    if (kIsWeb) {
      setState(() {
        _isFingerprintAvailable = false;
        _isCheckingBiometrics = false;
      });
      return;
    }

    try {
      final isSupported = await _fingerprintService.isDeviceSupported();
      final canCheck = await _fingerprintService.canCheckBiometrics();
      final hasFingerprint = await _fingerprintService.hasFingerprintSensor();

      setState(() {
        _isFingerprintAvailable = isSupported && (canCheck || hasFingerprint);
        _isCheckingBiometrics = false;
      });
    } catch (_) {
      setState(() {
        _isFingerprintAvailable = false;
        _isCheckingBiometrics = false;
      });
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    if (_isCheckingBiometrics || kIsWeb) return;

    final biometricType = await _fingerprintService.getBiometricTypeDescription();

    try {
      final success = await _fingerprintService.authenticate(
        reason: 'Authenticate with $biometricType to login',
      );

      if (!success || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Biometric check completed. Enter your credentials to continue."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {}
  }

  void login() {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return BlocListener<AuthBloc, AppAuthState>(
      listener: (context, state) {
        if (state.status == AppAuthStatus.authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (state.status == AppAuthStatus.needsHealthData) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HealthInputScreen()),
          );
        } else if (state.status == AppAuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: ${state.errorMessage}")),
          );
        }
      },
      child: Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF0B3B3B),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF062C30),
                  Color(0xFF0F766E),
                  Color(0xFF14B8A6),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -50,
                  child: _AuthOrb(size: 260, color: Colors.white.withValues(alpha: 0.08)),
                ),
                Positioned(
                  bottom: -120,
                  right: -60,
                  child: _AuthOrb(size: 340, color: Colors.white.withValues(alpha: 0.08)),
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
                                  Expanded(child: _buildShowcase(context)),
                                  const SizedBox(width: 28),
                                  SizedBox(width: 470, child: _buildFormCard(context)),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildShowcase(context, compact: true),
                                    const SizedBox(height: 24),
                                    _buildFormCard(context),
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
      ),
    );
  }

  Widget _buildShowcase(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "Built for mobile and web",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Health insights in a cleaner, more responsive workspace.",
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: theme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 34 : 46,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "Sign in to access reports, AI support, risk prediction, activity tracking, and your personalized dashboard.",
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: theme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: const [
            _InfoPill(icon: Icons.monitor_heart_outlined, label: "Real-time summaries"),
            _InfoPill(icon: Icons.psychology_alt_outlined, label: "AI-assisted guidance"),
            _InfoPill(icon: Icons.description_outlined, label: "Health reports"),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome back",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to continue your health journey.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            hint: "Email address",
            controller: emailController,
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hint: "Password",
            controller: passwordController,
            isPassword: true,
            icon: Icons.lock_outline_rounded,
          ),
          if (!kIsWeb && !_isCheckingBiometrics && _isFingerprintAvailable) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _authenticateWithFingerprint,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Use biometrics"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          BlocBuilder<AuthBloc, AppAuthState>(
            builder: (context, state) {
              return CustomButton(
                text: state.status == AppAuthStatus.loading ? "Signing in..." : "Sign In",
                onTap: state.status == AppAuthStatus.loading ? () {} : login,
                isLoading: state.status == AppAuthStatus.loading,
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New here? ",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "Create account",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
