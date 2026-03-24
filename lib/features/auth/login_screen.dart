import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../core/constants/colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/fingerprint_service.dart';
import '../health_input/health_input_screen.dart';
import '../dashboard/dashboard_screen.dart';
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
    try {
      final isSupported = await _fingerprintService.isDeviceSupported();
      final canCheck = await _fingerprintService.canCheckBiometrics();
      final hasFingerprint = await _fingerprintService.hasFingerprintSensor();
      
      setState(() {
        _isFingerprintAvailable = isSupported && (canCheck || hasFingerprint);
        _isCheckingBiometrics = false;
      });
      
      // Auto-prompt for fingerprint if available
      if (_isFingerprintAvailable) {
        // Small delay to let the UI build first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _authenticateWithFingerprint();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isFingerprintAvailable = false;
        _isCheckingBiometrics = false;
      });
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    if (_isCheckingBiometrics) return;
    
    final biometricType = await _fingerprintService.getBiometricTypeDescription();
    
    try {
      final success = await _fingerprintService.authenticate(
        reason: 'Authenticate with $biometricType to login',
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fingerprint verified! Please enter your credentials."),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Fingerprint authentication failed: $e');
    }
  }

  void login() {
    if (emailController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthLoginRequested(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

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
            SnackBar(content: Text("Login Failed: ${state.errorMessage}")),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                ),
              ),
              
              Positioned(
                top: -width * 0.3,
                right: -width * 0.2,
                child: Container(
                  width: width * 0.8,
                  height: width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.4),
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -width * 0.3,
                left: -width * 0.2,
                child: Container(
                  width: width * 0.8,
                  height: width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.4),
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: height * 0.1,
                  bottom: height * 0.05,
                  left: width * 0.08,
                  right: width * 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(width * 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.health_and_safety,
                            size: width * 0.15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: width * 0.04),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Health",
                              style: TextStyle(
                                fontSize: width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              "Guardian",
                              style: TextStyle(
                                fontSize: width * 0.04,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.08),

                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),

                    SizedBox(height: height * 0.02),

                    Text(
                      "Sign in to your account to continue",
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),

                    SizedBox(height: height * 0.06),

                    GlassCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.06,
                          vertical: height * 0.04,
                        ),
                        child: Column(
                          children: [
                            CustomTextField(
                              hint: "Email Address",
                              controller: emailController,
                              icon: Icons.email,
                            ),

                            SizedBox(height: height * 0.025),

                            CustomTextField(
                              hint: "Password",
                              controller: passwordController,
                              isPassword: true,
                              icon: Icons.lock,
                            ),

                            SizedBox(height: height * 0.02),

                            if (!_isCheckingBiometrics && _isFingerprintAvailable) ...[
                              GestureDetector(
                                onTap: _authenticateWithFingerprint,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.04,
                                    vertical: height * 0.015,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fingerprint,
                                        color: Colors.white,
                                        size: width * 0.06,
                                      ),
                                      SizedBox(width: width * 0.02),
                                      Text(
                                        "Use Fingerprint",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.035,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              Text(
                                "or",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: width * 0.03,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                            ],

                            BlocBuilder<AuthBloc, AppAuthState>(
                              builder: (context, state) {
                                return CustomButton(
                                  text: state.status == AppAuthStatus.loading 
                                      ? "Signing In..." 
                                      : "Sign In",
                                  onTap: state.status == AppAuthStatus.loading 
                                      ? () {} 
                                      : login,
                                  isLoading: state.status == AppAuthStatus.loading,
                                );
                              },
                            ),

                            SizedBox(height: height * 0.03),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    fontSize: width * 0.035,
                                    color: Colors.white70,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.035,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
