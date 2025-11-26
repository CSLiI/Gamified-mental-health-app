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
      // Boy character states
      'assets/images/Boy_Gif_33FPS/Boy_Happy.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Sad.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Angry.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Anxious.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Calm.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Excited.gif',
      'assets/images/Boy_Gif_33FPS/Boy_Tired.gif',

      // Girl character states
      'assets/images/Girl_Gif_33FPS/Girl_Happy.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Sad.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Angry.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Anxious.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Calm.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Excited.gif',
      'assets/images/Girl_Gif_33FPS/Girl_Tired.gif',
    ];

    // Preload all character GIFs in parallel
    await Future.wait(
      characterAssets.map((asset) => _precacheImage(context, asset)),
    );

    _isInitialized = true;
  }

  /// Preload specific character's all mood states
  Future<void> preloadCharacter(
      BuildContext context, String characterName) async {
    final moods = [
      'Happy',
      'Sad',
      'Angry',
      'Anxious',
      'Calm',
      'Excited',
      'Tired'
    ];

    await Future.wait(
      moods.map((mood) {
        final asset =
            'assets/images/${characterName}_Gif_33FPS/${characterName}_$mood.gif';
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
