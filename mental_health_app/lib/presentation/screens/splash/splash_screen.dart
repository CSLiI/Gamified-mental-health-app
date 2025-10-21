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
        print('🚫 No token found, redirecting to login');
        context.go('/login');
        return;
      }

      print('🔑 Token found, validating...');

      // Try to get user data to verify token is valid
      try {
        final user = await _apiService.getCurrentUser();
        print('✅ Token valid, user: ${user['first_name']}');

        // Token is valid, go to home
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        // Token is invalid or expired
        print('❌ Token invalid: $e');
        await _dioClient.logout(); // Clear invalid token
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      print('❌ Auth check error: $e');
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB0E0FF), // Lighter baby blue at top
              Color(0xFF89CFF0), // Baby blue at bottom
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
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(
                              (100 * _pulseController.value).round()),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Mental Health',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Your Journey to Wellness',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
