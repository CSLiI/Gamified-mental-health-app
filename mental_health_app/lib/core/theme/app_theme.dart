import 'package:flutter/material.dart';

// 🌿 Mental Health App Theme - Calming, Minimalistic Colors
class AppTheme {
  // Primary Colors - Soft Purple/Blue (Calming)
  static const Color primary = Color(0xFF6B7FD7);
  static const Color primaryLight = Color(0xFF9BA8E8);
  static const Color primaryDark = Color(0xFF4A5FC1);

  // Secondary Colors - Soft Green (Growth & Peace)
  static const Color secondary = Color(0xFF7BC8A4);
  static const Color secondaryLight = Color(0xFFA5E1C6);
  static const Color secondaryDark = Color(0xFF5BA888);

  // Background Colors - Soft Gradients
  static const Color backgroundStart = Color(0xFFF5F7FF);
  static const Color backgroundEnd = Color(0xFFE8EFFF);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textTertiary = Color(0xFF9BA8C7);

  // Accent Colors (for gamification)
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

  // 🌟 App-wide ThemeData
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundStart,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  // 🌤 Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  static  LinearGradient get cardGradient =>  const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surface, surfaceVariant],
      );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}

// 💨 Custom Shadows
class AppShadows {
  static List<BoxShadow> get small => [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}

