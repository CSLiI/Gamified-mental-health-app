import 'package:flutter/material.dart';

/// Centralized image/GIF cache manager for character assets
/// Preloads and caches character GIFs to prevent lag
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Set<String> _precachedImages = {};
  bool _isInitialized = false;

  /// Preload all character GIFs on app start (speeds up character display)
  Future<void> preloadCharacterAssets(BuildContext context) async {
    if (_isInitialized) return;

    final characterAssets = [
      // Boy character 1 states
      'assets/images/Boy_Gif_33FPS/HappyBoy1.gif',
      'assets/images/Boy_Gif_33FPS/SadBoy1.gif',
      'assets/images/Boy_Gif_33FPS/AngryBoy1.gif',
      'assets/images/Boy_Gif_33FPS/AnxiousBoy1.gif',
      'assets/images/Boy_Gif_33FPS/CalmBoy1.gif',
      'assets/images/Boy_Gif_33FPS/TiredBoy1.gif',

      // Boy character 2 states
      'assets/images/Boy_Gif_33FPS/HappyBoy2.gif',
      'assets/images/Boy_Gif_33FPS/SadBoy2.gif',
      'assets/images/Boy_Gif_33FPS/AngryBoy2.gif',
      'assets/images/Boy_Gif_33FPS/AnxiousBoy2.gif',
      'assets/images/Boy_Gif_33FPS/CalmBoy2.gif',
      'assets/images/Boy_Gif_33FPS/TiredBoy2.gif',

      // Girl character 1 states
      'assets/images/Girl_Gif_33FPS/HappyGirl1.gif',
      'assets/images/Girl_Gif_33FPS/SadGirl1.gif',
      'assets/images/Girl_Gif_33FPS/AngryGirl1.gif',
      'assets/images/Girl_Gif_33FPS/AnxiousGirl1.gif',
      'assets/images/Girl_Gif_33FPS/CalmGirl1.gif',
      'assets/images/Girl_Gif_33FPS/TiredGirl1.gif',

      // Girl character 2 states
      'assets/images/Girl_Gif_33FPS/HappyGirl2.gif',
      'assets/images/Girl_Gif_33FPS/SadGirl2.gif',
      'assets/images/Girl_Gif_33FPS/AngryGirl2.gif',
      'assets/images/Girl_Gif_33FPS/AnxiousGirl2.gif',
      'assets/images/Girl_Gif_33FPS/CalmGirl2.gif',
      'assets/images/Girl_Gif_33FPS/TiredGirl2.gif',
    ];

    // Preload all character GIFs in parallel
    await Future.wait(
      characterAssets.map((asset) => _precacheImage(context, asset)),
    );

    _isInitialized = true;
  }

  /// Preload specific character's all mood states
  Future<void> preloadCharacter(
      BuildContext context, String gender, int number) async {
    final moods = ['Happy', 'Sad', 'Angry', 'Anxious', 'Calm', 'Tired'];

    final genderCapitalized = gender.toLowerCase() == 'female' ? 'Girl' : 'Boy';

    await Future.wait(
      moods.map((mood) {
        final asset =
            'assets/images/${genderCapitalized}_Gif_33FPS/$mood$genderCapitalized$number.gif';
        return _precacheImage(context, asset);
      }),
    );
  }

  /// Internal method to precache image
  Future<void> _precacheImage(BuildContext context, String asset) async {
    if (_precachedImages.contains(asset)) return;

    try {
      await precacheImage(AssetImage(asset), context);
      _precachedImages.add(asset);
    } catch (e) {
      debugPrint('Failed to precache $asset: $e');
    }
  }

  /// Get optimized image widget with fade-in animation
  Widget buildCachedImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }

  /// Clear cache (for memory management)
  void clearCache() {
    _precachedImages.clear();
    _isInitialized = false;
  }
}
