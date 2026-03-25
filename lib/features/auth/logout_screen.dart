import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoggingOut = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    setState(() => _isLoggingOut = true);

    // Simulate a brief delay for animation
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await _authService.signOut();
      if (mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final height = screenSize.height;
    final contentWidth = width.clamp(0.0, 520.0).toDouble();
    final iconSize = contentWidth * 0.35;
    final titleSize = (contentWidth * 0.09).clamp(32.0, 54.0);
    final subtitleSize = (contentWidth * 0.04).clamp(16.0, 22.0);
    final horizontalPadding = width >= 900 ? 32.0 : 20.0;

    return Scaffold(
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
            // Animated AI Background
            _buildAnimatedBackground(width, height),

            // Floating orbs
            Positioned(
              top: height * 0.1,
              left: width * 0.1,
              child: _buildFloatingOrb(width * 0.15, Colors.blue.withOpacity(0.3)),
            ),
            Positioned(
              top: height * 0.2,
              right: width * 0.15,
              child: _buildFloatingOrb(width * 0.12, Colors.purple.withOpacity(0.3)),
            ),
            Positioned(
              bottom: height * 0.15,
              left: width * 0.2,
              child: _buildFloatingOrb(width * 0.1, Colors.cyan.withOpacity(0.3)),
            ),
            Positioned(
              bottom: height * 0.25,
              right: width * 0.1,
              child: _buildFloatingOrb(width * 0.08, Colors.pink.withOpacity(0.3)),
            ),

            // Main Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 620,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAIcon(iconSize),
                                SizedBox(height: (height * 0.05).clamp(20.0, 32.0)),
                                Text(
                                  "Goodbye!",
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Your health journey with AI continues",
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: (height * 0.06).clamp(24.0, 40.0)),
                                _buildInfoCard(contentWidth, height),
                                SizedBox(height: (height * 0.04).clamp(18.0, 28.0)),
                                _buildLogoutButton(contentWidth, height),
                                const SizedBox(height: 16),
                                _buildCancelButton(contentWidth, height),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(double width, double height) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
            Color(0xFF1a1a2e),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size(width, height),
      ),
    );
  }

  Widget _buildFloatingOrb(double size, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 2000 + size.toInt()),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(value * math.pi * 2) * 20,
            math.cos(value * math.pi * 2) * 20,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
            Color(0xFF6B8DD6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          // Inner ring
          Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          // Brain icon
          Icon(
            Icons.psychology,
            size: size * 0.42,
            color: Colors.white,
          ),
          // AI dots
          Positioned(
            top: size * 0.11,
            child: _buildAIDot(),
          ),
          Positioned(
            bottom: size * 0.11,
            child: _buildAIDot(),
          ),
          Positioned(
            left: size * 0.11,
            child: _buildAIDot(),
          ),
          Positioned(
            right: size * 0.11,
            child: _buildAIDot(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(value),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(double width, double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: (width * 0.06).clamp(22.0, 30.0),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Session Secured",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (width * 0.04).clamp(18.0, 24.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Your data is safe with us",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: (width * 0.028).clamp(13.0, 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          const Divider(color: Colors.white24),
          SizedBox(height: height * 0.02),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildStatItem("Health", "85%", Colors.cyan),
              _buildStatItem("Score", "92%", Colors.green),
              _buildStatItem("Level", "Pro", Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(double width, double height) {
    return GestureDetector(
      onTap: _isLoggingOut ? null : logout,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: (height * 0.018).clamp(14.0, 18.0)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoggingOut
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: (width * 0.05).clamp(20.0, 26.0),
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (width * 0.045).clamp(18.0, 24.0),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(double width, double height) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            color: Colors.white60,
            size: (width * 0.04).clamp(16.0, 22.0),
          ),
          SizedBox(width: width * 0.02),
          Text(
            "Cancel - Go Back",
            style: TextStyle(
              color: Colors.white60,
              fontSize: (width * 0.035).clamp(14.0, 18.0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
