import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../constants/storage_keys.dart';

class ThemePalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });
}

class ThemeProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Default Palette (Ocean Breeze - Professional & Calming)
  static const _defaultPalette = ThemePalette(
    primary: Color(0xFF5CACEE),
    secondary: Color(0xFF4A9FD8),
    background: Color(0xFFF5F7FA), // Soft blue-grey (Original Default)
    surface: Colors.white,
    textPrimary: Color(0xFF2D3748), // Dark slate
    textSecondary: Color(0xFF718096), // Medium slate
    accent: Color(0xFF3182CE),
  );

  ThemePalette _currentPalette = _defaultPalette;
  String _currentFontFamily = 'Nunito'; // Default font

  // Equipped banner data
  Map<String, dynamic>? _equippedBanner;

  // Built-in theme catalog
  final List<Map<String, dynamic>> _builtinThemes = [
    {
      'id': 10000,
      'category': 'themes',
      'name': 'Ocean Breeze',
      'palette': const ThemePalette(
        primary: Color(0xFF5CACEE),
        secondary: Color(0xFF4A9FD8),
        background: Color(0xFFF5F7FA),
        surface: Colors.white,
        textPrimary: Color(0xFF2D3748),
        textSecondary: Color(0xFF718096),
        accent: Color(0xFF3182CE),
      ),
    },
    {
      'id': 10001,
      'category': 'themes',
      'name': 'Sunset Glow',
      'palette': const ThemePalette(
        primary: Color(0xFFFF8E53),
        secondary: Color(0xFFFF6B6B),
        background: Color(0xFFFFF5F5), // Soft warm white
        surface: Colors.white,
        textPrimary: Color(0xFF742A2A), // Dark red-brown
        textSecondary: Color(0xFFA15C5C),
        accent: Color(0xFFDD6B20),
      ),
    },
    {
      'id': 10002,
      'category': 'themes',
      'name': 'Forest Calm',
      'palette': const ThemePalette(
        primary: Color(0xFF48BB78),
        secondary: Color(0xFF38A169),
        background: Color(0xFFF0FFF4), // Soft mint
        surface: Colors.white,
        textPrimary: Color(0xFF22543D), // Dark green
        textSecondary: Color(0xFF48BB78),
        accent: Color(0xFF2F855A),
      ),
    },
    {
      'id': 10003,
      'category': 'themes',
      'name': 'Lavender Dream',
      'palette': const ThemePalette(
        primary: Color(0xFF9F7AEA),
        secondary: Color(0xFF805AD5),
        background: Color(0xFFFAF5FF), // Soft purple
        surface: Colors.white,
        textPrimary: Color(0xFF44337A), // Dark purple
        textSecondary: Color(0xFF6B46C1),
        accent: Color(0xFF553C9A),
      ),
    },
    {
      'id': 10004,
      'category': 'themes',
      'name': 'Midnight Sky',
      'palette': const ThemePalette(
        primary: Color(0xFF63B3ED),
        secondary: Color(0xFF4299E1),
        background: Color(0xFF1A202C), // Dark mode bg
        surface: Color(0xFF2D3748), // Dark mode surface
        textPrimary: Color(0xFFF7FAFC), // White text
        textSecondary: Color(0xFFA0AEC0), // Grey text
        accent: Color(0xFF90CDF4),
      ),
    },
  ];

  // Font Catalog
  final List<Map<String, dynamic>> _builtinFonts = [
    {
      'id': 10010,
      'category': 'fonts',
      'name': 'Nunito (Default)',
      'fontFamily': 'Nunito',
    },
    {
      'id': 10011,
      'category': 'fonts',
      'name': 'Outfit (Modern)',
      'fontFamily': 'Outfit',
    },
    {
      'id': 10012,
      'category': 'fonts',
      'name': 'Inter (Professional)',
      'fontFamily': 'Inter',
    },
    {
      'id': 10013,
      'category': 'fonts',
      'name': 'Quicksand (Friendly)',
      'fontFamily': 'Quicksand',
    },
    {
      'id': 10014,
      'category': 'fonts',
      'name': 'Playfair (Elegant)',
      'fontFamily': 'Playfair Display',
    },
  ];

  final List<Map<String, dynamic>> _builtinBanners = [
    {
      'id': 10005,
      'category': 'banners',
      'name': 'Achievement Master',
      'color1': const Color(0xFFFDC830), // Canary Gold
      'color2': const Color(0xFFF37335), // Deep Orange
    },
    {
      'id': 10006,
      'category': 'banners',
      'name': 'Wellness Champion',
      'color1': const Color(0xFF43E97B), // Emerald
      'color2': const Color(0xFF38F9D7), // Turquoise
    },
    {
      'id': 10007,
      'category': 'banners',
      'name': 'Mood Warrior',
      'color1': const Color(0xFFFA709A), // Hot Pink
      'color2': const Color(0xFFFF8E53), // Coral Orange
    },
    {
      'id': 10008,
      'category': 'banners',
      'name': 'Streak Hero',
      'color1': const Color(0xFFDA22FF), // Neon Purple
      'color2': const Color(0xFF9733EE), // Deep Violet
    },
    {
      'id': 10009,
      'category': 'banners',
      'name': 'Journal Master',
      'color1': const Color(0xFFA18CD1), // Lavender
      'color2': const Color(0xFFFBC2EB), // Rose
    },
  ];

  // Getters
  ThemePalette get palette => _currentPalette;
  Color get primaryColor => _currentPalette.primary;
  Color get secondaryColor => _currentPalette.secondary;
  String get fontFamily => _currentFontFamily;
  Map<String, dynamic>? get equippedBanner => _equippedBanner;

  bool _isInitialized = false;

  ThemeProvider() {
    // Don't load in constructor - causes crashes with secure storage
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadEquippedTheme();
      _isInitialized = true;
    }
  }

  Future<void> _loadEquippedTheme([int? userId]) async {
    try {
      print('🎨 ThemeProvider: Loading equipped theme from storage...');

      // Reset to defaults
      _currentPalette = _defaultPalette;
      _currentFontFamily = 'Nunito';
      _equippedBanner = null;

      // Get user ID from storage if not provided
      if (userId == null) {
        final userIdStr =
            await _secureStorage.read(key: StorageKeys.currentUserId);
        if (userIdStr != null) {
          userId = int.tryParse(userIdStr);
        }
      }

      if (userId == null) {
        print('🎨 ThemeProvider: No user ID available, using defaults');
        notifyListeners();
        return;
      }

      // Load equipped rewards
      final equippedJson = await _secureStorage.read(
          key: StorageKeys.builtinEquippedRewards(userId));

      if (equippedJson != null) {
        final equipped =
            (jsonDecode(equippedJson) as List).cast<Map<String, dynamic>>();

        // Load purchased items for validation
        final purchasedJson = await _secureStorage.read(
            key: StorageKeys.builtinUserRewards(userId));
        final purchased = purchasedJson != null
            ? (jsonDecode(purchasedJson) as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        // --- THEMES ---
        final equippedTheme = equipped.firstWhere(
          (r) => r['category'] == 'themes',
          orElse: () => <String, dynamic>{},
        );

        if (equippedTheme.isNotEmpty) {
          final themeId = equippedTheme['reward_id'];
          final isPurchased = purchased.any((p) => p['reward_id'] == themeId);

          if (isPurchased) {
            final themeReward = _builtinThemes.firstWhere(
              (t) => t['id'] == themeId,
              orElse: () => _builtinThemes[0],
            );
            _currentPalette = themeReward['palette'] as ThemePalette;
            print('🎨 ThemeProvider: Loaded theme: ${themeReward['name']}');
          }
        }

        // --- FONTS ---
        final equippedFont = equipped.firstWhere(
          (r) => r['category'] == 'fonts',
          orElse: () => <String, dynamic>{},
        );

        if (equippedFont.isNotEmpty) {
          final fontId = equippedFont['reward_id'];
          final isPurchased = purchased.any((p) => p['reward_id'] == fontId);

          if (isPurchased) {
            final fontReward = _builtinFonts.firstWhere(
              (f) => f['id'] == fontId,
              orElse: () => _builtinFonts[0],
            );
            _currentFontFamily = fontReward['fontFamily'] as String;
            print('🎨 ThemeProvider: Loaded font: ${fontReward['name']}');
          }
        }

        // --- BANNERS ---
        final equippedBannerData = equipped.firstWhere(
          (r) => r['category'] == 'banners',
          orElse: () => <String, dynamic>{},
        );

        if (equippedBannerData.isNotEmpty) {
          final bannerId = equippedBannerData['reward_id'];
          final isPurchased = purchased.any((p) => p['reward_id'] == bannerId);

          if (isPurchased) {
            final bannerReward = _builtinBanners.firstWhere(
              (b) => b['id'] == bannerId,
              orElse: () => <String, dynamic>{},
            );
            if (bannerReward.isNotEmpty) {
              _equippedBanner = bannerReward;
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ ThemeProvider: Error loading theme: $e');
    }
  }

  Future<void> refreshTheme([int? userId]) async {
    print('🔄 ThemeProvider: Refreshing theme...');
    _isInitialized = false;
    await _loadEquippedTheme(userId);
    _isInitialized = true;
  }

  Future<void> clearTheme() async {
    print('🧹 ThemeProvider: Clearing theme on logout...');
    _currentPalette = _defaultPalette;
    _currentFontFamily = 'Nunito';
    _equippedBanner = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Helper for gradients if needed (kept for compatibility)
  LinearGradient getThemeGradient() {
    return LinearGradient(
      colors: [_currentPalette.primary, _currentPalette.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient? getBannerGradient() {
    if (_equippedBanner == null) return null;
    return LinearGradient(
      colors: [
        _equippedBanner!['color1'] as Color,
        _equippedBanner!['color2'] as Color,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
