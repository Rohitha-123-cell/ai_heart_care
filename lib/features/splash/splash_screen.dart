import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../health_input/health_input_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/constants/colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

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

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user != null) {
      // User is logged in, check for health data
      final hasHealthData = await _checkUserHasHealthData(user.id);
      
      if (!mounted) return;

      if (hasHealthData) {
        // User has health data, go to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // User doesn't have health data, go to health input
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthInputScreen()),
        );
      }
    } else {
      // User not logged in, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<bool> _checkUserHasHealthData(String userId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      // If error, assume no health data
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              color: AppColors.primary,
              size: width * 0.2,
            ),
            const SizedBox(height: 20),
            Text(
              "AI Health Guardian",
              style: TextStyle(
                fontSize: width * 0.07,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
