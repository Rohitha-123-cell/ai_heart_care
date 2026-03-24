import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'services/supabase_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/health_data/health_data_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init();

  runApp(const HealthGuardianApp());
}

class HealthGuardianApp extends StatelessWidget {
  const HealthGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        BlocProvider<HealthDataBloc>(
          create: (_) => HealthDataBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "AI Health Guardian",
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
