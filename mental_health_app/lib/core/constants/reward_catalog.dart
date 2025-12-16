import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RewardCatalog {
  static final List<Map<String, dynamic>> rewards = [
    // Themes (app background gradients - MUST match ThemeProvider IDs)
    {
      'id': 10000,
      'name': 'Ocean Breeze',
      'category': 'themes',
      'xp_cost': 50,
      'tier': 1,
      'preview': 'theme_ocean',
      'color1': const Color(0xFF5CACEE),
      'color2': const Color(0xFF4A9FD8),
    },
    {
      'id': 10001,
      'name': 'Sunset Glow',
      'category': 'themes',
      'xp_cost': 80,
      'tier': 1,
      'preview': 'theme_sunset',
      'color1': const Color(0xFFFF6B6B),
      'color2': const Color(0xFFFFD93D),
    },
    {
      'id': 10002,
      'name': 'Forest Calm',
      'category': 'themes',
      'xp_cost': 100,
      'tier': 2,
      'preview': 'theme_forest',
      'color1': const Color(0xFF6BCF7F),
      'color2': const Color(0xFF4CAF50),
    },
    {
      'id': 10003,
      'name': 'Lavender Dream',
      'category': 'themes',
      'xp_cost': 120,
      'tier': 2,
      'preview': 'theme_lavender',
      'color1': const Color(0xFF9C27B0),
      'color2': const Color(0xFF7B1FA2),
    },
    {
      'id': 10004,
      'name': 'Midnight Sky',
      'category': 'themes',
      'xp_cost': 140,
      'tier': 3,
      'preview': 'theme_midnight',
      'color1': const Color(0xFF1A237E),
      'color2': const Color(0xFF0D47A1),
    },
    // Fonts (Global App Typography)
    {
      'id': 10010,
      'name': 'Nunito (Default)',
      'category': 'fonts',
      'xp_cost': 0,
      'tier': 1,
      'preview': 'font_nunito',
      'color1': const Color(0xFFE2E8F0),
      'color2': const Color(0xFFCBD5E0),
    },
    {
      'id': 10011,
      'name': 'Outfit (Modern)',
      'category': 'fonts',
      'xp_cost': 100,
      'tier': 2,
      'preview': 'font_outfit',
      'color1': const Color(0xFFE2E8F0),
      'color2': const Color(0xFFCBD5E0),
    },
    {
      'id': 10012,
      'name': 'Inter (Professional)',
      'category': 'fonts',
      'xp_cost': 150,
      'tier': 2,
      'preview': 'font_inter',
      'color1': const Color(0xFFE2E8F0),
      'color2': const Color(0xFFCBD5E0),
    },
    {
      'id': 10013,
      'name': 'Quicksand (Friendly)',
      'category': 'fonts',
      'xp_cost': 120,
      'tier': 2,
      'preview': 'font_quicksand',
      'color1': const Color(0xFFE2E8F0),
      'color2': const Color(0xFFCBD5E0),
    },
    {
      'id': 10014,
      'name': 'Playfair (Elegant)',
      'category': 'fonts',
      'xp_cost': 200,
      'tier': 3,
      'preview': 'font_playfair',
      'color1': const Color(0xFFE2E8F0),
      'color2': const Color(0xFFCBD5E0),
    },
    // Banners (character card decorations - MUST match ThemeProvider IDs)
    {
      'id': 10005,
      'name': 'Achievement Master',
      'category': 'banners',
      'xp_cost': 90,
      'tier': 1,
      'preview': 'banner_achievement',
      'color1': const Color(0xFFFFE082), // Soft Amber
      'color2': const Color(0xFFFFCC80), // Soft Orange
    },
    {
      'id': 10006,
      'name': 'Wellness Champion',
      'category': 'banners',
      'xp_cost': 100,
      'tier': 1,
      'preview': 'banner_wellness',
      'color1': const Color(0xFFA5D6A7), // Soft Green
      'color2': const Color(0xFF80CBC4), // Soft Teal
    },
    {
      'id': 10007,
      'name': 'Mood Warrior',
      'category': 'banners',
      'xp_cost': 110,
      'tier': 2,
      'preview': 'banner_mood',
      'color1': const Color(0xFFF48FB1), // Soft Pink
      'color2': const Color(0xFFFFAB91), // Soft Coral
    },
    {
      'id': 10008,
      'name': 'Streak Hero',
      'category': 'banners',
      'xp_cost': 120,
      'tier': 2,
      'preview': 'banner_streak',
      'color1': const Color(0xFFCE93D8), // Soft Purple
      'color2': const Color(0xFFB39DDB), // Soft Deep Purple
    },
    {
      'id': 10009,
      'name': 'Journal Master',
      'category': 'banners',
      'xp_cost': 130,
      'tier': 2,
      'preview': 'banner_journal',
      'color1': const Color(0xFFB39DDB), // Deep Lavender
      'color2': const Color(0xFFF48FB1), // Soft Rose
    },
  ];

  static Map<String, dynamic>? getRewardById(int id) {
    try {
      return rewards.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
