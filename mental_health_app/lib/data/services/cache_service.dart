import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized caching service for all API responses
/// Automatically used by ApiService to cache data across app
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Initialize cache (call once in main.dart)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cache duration strategies
  static const Duration shortCache = Duration(minutes: 2); // Mood logs, todos
  static const Duration mediumCache = Duration(minutes: 10); // Profile data
  static const Duration longCache =
      Duration(hours: 1); // Static data (characters, achievements)

  /// Get cached data (checks memory first, then disk)
  Future<T?> get<T>(
    String key, {
    Duration maxAge = mediumCache,
    T Function(dynamic)? fromJson,
  }) async {
    // Check memory cache first (fastest)
    if (_memoryCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) < maxAge) {
        return _memoryCache[key] as T?;
      } else {
        // Expired in memory
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    // Check disk cache (slower but persistent)
    if (_prefs == null) await initialize();
    final String? jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      final timestamp = _prefs?.getInt('${key}_timestamp');
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) < maxAge) {
          final data = json.decode(jsonString);
          // Restore to memory cache
          _memoryCache[key] = fromJson != null ? fromJson(data) : data;
          _cacheTimestamps[key] = cacheTime;
          return _memoryCache[key] as T?;
        }
      }
    }

    return null;
  }

  /// Set cache data (stores in both memory and disk)
  Future<void> set(String key, dynamic value) async {
    // Store in memory cache
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();

    // Store in disk cache
    if (_prefs == null) await initialize();
    final jsonString = json.encode(value);
    await _prefs?.setString(key, jsonString);
    await _prefs?.setInt(
        '${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear specific cache key
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    if (_prefs == null) await initialize();
    await _prefs?.remove(key);
    await _prefs?.remove('${key}_timestamp');
  }

  /// Clear all cache (for logout)
  Future<void> clearAll() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    if (_prefs == null) await initialize();
    await _prefs?.clear();
  }

  /// Clear expired cache entries
  Future<void> clearExpired({Duration maxAge = mediumCache}) async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // Check memory cache
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > maxAge) {
        expiredKeys.add(key);
      }
    });

    // Remove expired entries
    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  /// Preload critical data for faster app start
  Future<void> preloadCriticalData(Future<void> Function() loadFunction) async {
    // This allows screens to load data in parallel on app start
    await loadFunction();
  }
}

/// Cache keys used throughout the app
class CacheKeys {
  // User profile
  static const String userProfile = 'user_profile';
  static const String userCharacter = 'user_character';
  static const String characterMoodState = 'character_mood_state';

  // Mood logs
  static const String recentMoods = 'recent_moods';
  static String userMoods(int userId) => 'user_moods_$userId';

  // Todos
  static const String myTodos = 'my_todos';

  // Journal entries
  static const String recentJournals = 'recent_journals';

  // Friends
  static const String friendsList = 'friends_list';
  static String friendProfile(int friendId) => 'friend_profile_$friendId';
  static String friendMood(int friendId) => 'friend_mood_$friendId';

  // Static data (rarely changes)
  static const String allCharacters = 'all_characters';
  static const String allAchievements = 'all_achievements';
  static const String allRewards = 'all_rewards';

  // Streaks
  static const String currentStreak = 'current_streak';

  // Notifications
  static const String notifications = 'notifications';
  static const String unreadCount = 'unread_count';
}
