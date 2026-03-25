import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../health_input/health_input_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> register() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HealthInputScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                Color(0xFF22C55E),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
                child: Padding(
                  padding: Responsive.pagePadding(context),
                  child: isDesktop
                      ? Row(
                          children: [
                            Expanded(child: _buildIntro(context)),
                            const SizedBox(width: 28),
                            SizedBox(width: 470, child: _buildCard(context)),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildIntro(context, compact: true),
                              const SizedBox(height: 24),
                              _buildCard(context),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, {bool compact = false}) {
    final textTheme = Theme.of(context).textTheme;

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
            "Create your responsive health workspace",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Start with a cleaner account setup experience.",
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 34 : 46,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "Create an account to save reports, risk analysis, wellness progress, and AI-supported insights.",
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create account",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your details and continue to your health profile.",
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
          const SizedBox(height: 18),
          CustomButton(
            text: _isLoading ? "Creating account..." : "Create Account",
            onTap: _isLoading ? () {} : register,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  "Sign in",
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
