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

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();
  final DioClient _dioClient = DioClient();

  @override
  void initState() {
    super.initState();
    _checkAuth();
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
          gradient: AppColors.primaryGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Mental Health',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Your Journey to Wellness',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}