import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/dio_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final DioClient _dioClient = DioClient();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkAuth();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if token exists
      final token = await _dioClient.getToken();

      if (token == null || token.isEmpty) {
        // No token, go to login
        // print('🚫 No token found, redirecting to login');
        context.go('/login');
        return;
      }

      // print('🔑 Token found, validating...');

      // Try to get user data to verify token is valid
      try {
        final user = await _apiService.getCurrentUser();
        // print('✅ Token valid, user: ${user['first_name']}');

        // Token is valid, go to home
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        // Token is invalid or expired
        // print('❌ Token invalid: $e');
        await _dioClient.logout(); // Clear invalid token
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      // print('❌ Auth check error: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FE),
              Color(0xFFE8EAFC),
              Color(0xFFD6D9FA),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pulsing icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (10 * _pulseController.value),
                    height: 120 + (10 * _pulseController.value),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C5CE7)
                              .withValues(alpha: 0.3 * _pulseController.value),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Mental Wellness',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your journey to better mental health',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                color: Color(0xFF6C5CE7),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
