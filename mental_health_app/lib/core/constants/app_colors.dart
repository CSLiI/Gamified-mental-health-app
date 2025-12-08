import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Calming sage green theme
  static const Color primary = Color(0xFF7FB3A7);
  static const Color primaryLight = Color(0xFFA8D5C9);
  static const Color primaryDark = Color(0xFF5A9488);

  // Secondary Colors - Soft lavender accent
  static const Color secondary = Color(0xFFB4A5D8);
  static const Color secondaryLight = Color(0xFFD4C9E8);
  static const Color secondaryDark = Color(0xFF9382BC);

  // Background Colors - Soft gradient theme
  static const Color background = Color(0xFFF8F9FA); // Very light gray
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Light gray

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Mood Colors - Softer, therapeutic tones
  static const Color moodHappy = Color(0xFFFDD88C);
  static const Color moodSad = Color(0xFF8BAED1);
  static const Color moodAnxious = Color(0xFFE8A598);
  static const Color moodCalm = Color(0xFF9BC9A3);
  static const Color moodAngry = Color(0xFFD9897C);
  static const Color moodTired = Color(0xFFB2A1CD);

  // Character States - Gentle wellness indicators
  static const Color stateThriving = Color(0xFF81C784);
  static const Color stateContent = Color(0xFFA5D6A7);
  static const Color stateStruggling = Color(0xFFFFB74D);
  static const Color stateNeedsSupport = Color(0xFFEF9A9A);

  // Environment Colors - Nature-inspired calm
  static const Color envVibrant = Color(0xFFFEE8A7);
  static const Color envPeaceful = Color(0xFFA8D5BA);
  static const Color envCloudy = Color(0xFFD4DBE5);
  static const Color envStormy = Color(0xFFA4B0BE);

  // Status Colors - Softer feedback
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Rarity Colors (for rewards)
  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityRare = Color(0xFF2196F3);
  static const Color rarityEpic = Color(0xFF9C27B0);
  static const Color rarityLegendary = Color(0xFFFF9800);

  // Game Theme Colors - Calming pastels
  static const Color gameBlue = Color(0xFF90CAF9);
  static const Color gamePurple = Color(0xFFB39DDB);
  static const Color gameGreen = Color(0xFF80CBC4);
  static const Color gamePink = Color(0xFFF48FB1);
  static const Color gameYellow = Color(0xFFFFF59D);

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

  // Sky Blue Background Gradient (More visible)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF81D4FA),
      Color(0xFF4FC3F7)
    ], // Medium to vibrant sky blue
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Alternative Sky Blue Gradient
  static const LinearGradient skyBlueGradient = LinearGradient(
    colors: [Color(0xFF80DEEA), Color(0xFF4DD0E1)], // Cyan sky blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Game Theme Gradients - Therapeutic and calming
  static const LinearGradient softGameGradient = LinearGradient(
    colors: [Color(0xFFB3E5F0), Color(0xFFC5E8D4)], // Sky to sage
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dreamyGradient = LinearGradient(
    colors: [Color(0xFFD4C5E8), Color(0xFFB3E5F0)], // Lavender to sky
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient galaxyGradient = LinearGradient(
    colors: [
      Color(0xFF7986A6),
      Color(0xFF8BA3C4)
    ], // Muted indigo to periwinkle
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient pastelsGradient = LinearGradient(
    colors: [Color(0xFFBFE3D0), Color(0xFFE8F5E0)], // Mint to pale green
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
