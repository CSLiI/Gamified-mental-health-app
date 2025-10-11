// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B7FD7);
  static const Color primaryLight = Color(0xFF9BA8E8);
  static const Color primaryDark = Color(0xFF4A5FC1);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF7BC8A4);
  static const Color secondaryLight = Color(0xFFA5E1C6);
  static const Color secondaryDark = Color(0xFF5BA888);
  
  // Background
  static const Color background = Color(0xFFF5F7FF);
  static const Color backgroundEnd = Color(0xFFE8EFFF);
  static const Color backgroundStart = Color(0xFFF5F7FF);
  
  // Surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textTertiary = Color(0xFF9BA8C7);
  
  // Accent Colors
  static const Color accentGold = Color(0xFFFFD93D);
  static const Color accentRose = Color(0xFFFF8FAB);
  static const Color accentMint = Color(0xFF6EFFC4);
  
  // Mood Colors
  static const Color moodHappy = Color(0xFFFFD93D);
  static const Color moodCalm = Color(0xFF7BC8A4);
  static const Color moodSad = Color(0xFF8B9FE8);
  static const Color moodAnxious = Color(0xFFFF8FAB);
  static const Color moodTired = Color(0xFFB8B8D1);
  static const Color moodAngry = Color(0xFFFF6B6B);
  
  // Status Colors
  static const Color success = Color(0xFF5BCB97);
  static const Color warning = Color(0xFFFFBE5C);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF6B7FD7);
  
  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );
}

// Shadow utilities
class AppShadows {
  static List<BoxShadow> get small {
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  static List<BoxShadow> get medium {
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
  
  static List<BoxShadow> get large {
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.16),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ];
  }
}