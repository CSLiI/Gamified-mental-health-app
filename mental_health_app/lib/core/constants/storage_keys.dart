/// Centralized storage keys for consistent data access across the app.
///
/// This file contains all storage key constants used in SharedPreferences
/// and FlutterSecureStorage to prevent typos and ensure consistency.
class StorageKeys {
  StorageKeys._(); // Private constructor to prevent instantiation

  // ==================== Authentication Keys ====================
  /// JWT authentication token stored in secure storage
  static const String authToken = 'auth_token';

  /// Current logged-in user's ID stored in secure storage
  static const String currentUserId = 'current_user_id';

  // ==================== Builtin Rewards Keys (User-Specific) ====================
  /// Purchased builtin rewards (themes, banners, etc.) - Format: builtin_user_rewards_{userId}
  static String builtinUserRewards(int userId) =>
      'builtin_user_rewards_$userId';

  /// Equipped builtin rewards - Format: builtin_equipped_rewards_{userId}
  static String builtinEquippedRewards(int userId) =>
      'builtin_equipped_rewards_$userId';

  /// XP spent on builtin rewards - Format: builtin_xp_spent_{userId}
  static String builtinXpSpent(int userId) => 'builtin_xp_spent_$userId';

  // ==================== Legacy Builtin Rewards Keys (No userId) ====================
  /// Legacy key for purchased builtin rewards (without user ID) - should be cleaned up
  static const String legacyBuiltinUserRewards = 'builtin_user_rewards';

  /// Legacy key for equipped builtin rewards (without user ID) - should be cleaned up
  static const String legacyBuiltinEquippedRewards = 'builtin_equipped_rewards';

  /// Legacy key for XP spent (without user ID) - should be cleaned up
  static const String legacyBuiltinXpSpent = 'builtin_xp_spent';

  /// List of all legacy builtin rewards keys for cleanup
  static const List<String> legacyBuiltinRewardsKeys = [
    legacyBuiltinUserRewards,
    legacyBuiltinEquippedRewards,
    legacyBuiltinXpSpent,
  ];

  // ==================== Character Keys (User-Specific) ====================
  /// Selected character ID - Format: selected_character_id_{userId}
  static String selectedCharacterId(int userId) =>
      'selected_character_id_$userId';

  /// Selected character gender - Format: selected_character_gender_{userId}
  static String selectedCharacterGender(int userId) =>
      'selected_character_gender_$userId';

  /// Selected character number - Format: selected_character_number_{userId}
  static String selectedCharacterNumber(int userId) =>
      'selected_character_number_$userId';

  // ==================== Legacy Character Keys (No userId) ====================
  /// Legacy character ID key (without user ID) - should be cleaned up
  static const String legacySelectedCharacterId = 'selected_character_id';

  /// Legacy character gender key (without user ID) - should be cleaned up
  static const String legacySelectedCharacterGender =
      'selected_character_gender';

  /// Legacy character number key (without user ID) - should be cleaned up
  static const String legacySelectedCharacterNumber =
      'selected_character_number';

  // ==================== Mood Keys (User-Specific) ====================
  /// Last selected mood - Format: last_selected_mood_{userId}
  static String lastSelectedMood(int userId) => 'last_selected_mood_$userId';

  /// Legacy mood key (without user ID) - should be cleaned up
  static const String legacyLastSelectedMood = 'last_selected_mood';

  // ==================== Cache Keys ====================
  /// Rewards data cache key
  static const String rewardsDataCache = 'rewards_data';

  /// Profile data cache key
  static const String profileDataCache = 'profile_data';

  // ==================== Storage Key Patterns (for bulk operations) ====================
  /// Pattern to match all character-related keys
  static const String characterKeyPattern = 'selected_character_';

  /// Pattern to match all mood-related keys
  static const String moodKeyPattern = 'last_selected_mood_';

  /// Pattern to match all user-specific keys
  static const String userKeyPattern = '_user_';

  // ==================== Helper Methods ====================
  /// Get all legacy keys that should be cleaned up on login/logout
  static List<String> getLegacyKeys() => [
        legacySelectedCharacterId,
        legacySelectedCharacterGender,
        legacySelectedCharacterNumber,
        legacyLastSelectedMood,
        ...legacyBuiltinRewardsKeys,
      ];

  /// Check if a key is a legacy (non-user-specific) key
  static bool isLegacyKey(String key) => getLegacyKeys().contains(key);

  /// Check if a key contains user-specific patterns
  static bool isUserSpecificKey(String key) =>
      key.contains(characterKeyPattern) ||
      key.contains(moodKeyPattern) ||
      key.contains(userKeyPattern);
}
