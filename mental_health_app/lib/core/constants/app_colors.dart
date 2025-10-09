import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Calming blue/purple theme
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryLight = Color(0xFF9B7EFF);
  static const Color primaryDark = Color(0xFF4A2FCC);
  
  // Secondary Colors - Warm accent
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF9BBD);
  static const Color secondaryDark = Color(0xFFCC4A7A);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F8);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Mood Colors
  static const Color moodHappy = Color(0xFFFFC107);
  static const Color moodSad = Color(0xFF64B5F6);
  static const Color moodAnxious = Color(0xFFFF7043);
  static const Color moodCalm = Color(0xFF66BB6A);
  static const Color moodAngry = Color(0xFFEF5350);
  static const Color moodTired = Color(0xFF9575CD);
  
  // Character States
  static const Color stateThriving = Color(0xFF4CAF50);
  static const Color stateContent = Color(0xFF8BC34A);
  static const Color stateStruggling = Color(0xFFFF9800);
  static const Color stateNeedsSupport = Color(0xFFFF5252);
  
  // Environment Colors
  static const Color envVibrant = Color(0xFFFFD54F);
  static const Color envPeaceful = Color(0xFF81C784);
  static const Color envCloudy = Color(0xFFB0BEC5);
  static const Color envStormy = Color(0xFF78909C);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Rarity Colors (for rewards)
  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityRare = Color(0xFF2196F3);
  static const Color rarityEpic = Color(0xFF9C27B0);
  static const Color rarityLegendary = Color(0xFFFF9800);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8F9FE), Color(0xFFE8EAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}