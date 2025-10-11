import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // TODO: Check if user is logged in and has completed onboarding
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 60,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(delay: 200.ms, duration: 600.ms)
                  .then()
                  .shimmer(duration: 1000.ms),
              
              const SizedBox(height: 24),
              
              Text(
                'MindfulMe',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Your Journey to Wellness',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}