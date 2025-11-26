import 'package:dio/dio.dart';

class ApiConstants {
  // ⚠️ IMPORTANT: Change this based on your testing device

  // FOR ANDROID EMULATOR (default):
  static const String baseUrl = 'http://192.168.68.103:8000';
  //static const String baseUrl = 'http://10.0.2.2:8000';
  // FOR iOS SIMULATOR (uncomment this and comment above):
  // static const String baseUrl = 'http://localhost:8000';

  // FOR PHYSICAL DEVICE (find your computer's IP and use it):
  // Windows: Run 'ipconfig' in cmd, look for IPv4 Address
  // Mac/Linux: Run 'ifconfig' or 'ip addr', look for inet
  // Example: static const String baseUrl = 'http://192.168.1.100:8000';

  // ====== HOW TO FIND YOUR IP ADDRESS ======
  //
  // Windows:
  // 1. Open Command Prompt
  // 2. Type: ipconfig
  // 3. Look for "IPv4 Address" under your active network
  // 4. Use that IP (e.g., 192.168.1.100)
  //
  // Mac:
  // 1. Open Terminal
  // 2. Type: ifconfig | grep "inet "
  // 3. Look for an IP that's NOT 127.0.0.1
  // 4. Use that IP (e.g., 192.168.1.100)
  //
  // Linux:
  // 1. Open Terminal
  // 2. Type: ip addr show
  // 3. Look for "inet" under your active connection
  // 4. Use that IP (e.g., 192.168.1.100)

  // ==================== Endpoints ====================

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // User Endpoints
  static const String users = '/users';
  static const String userInterests = '/users/me/interests';

  // Mood Endpoints
  static const String moods = '/moods';
  static const String moodStatistics = '/moods/statistics';

  // Journal Endpoints
  static const String journals = '/journals';
  static const String journalSearch = '/journals/search';
  static const String journalPrompts = '/journal-prompts';
  static const String dailyPrompt = '/journal-prompts/daily';

  // Todo Endpoints
  static const String todos = '/todos';
  static const String todoStatistics = '/todos/statistics';

  // Character Endpoints
  static const String characters = '/characters';
  static const String myCharacters = '/characters/me/characters';
  static const String currentCharacter = '/characters/me/current';
  static const String chooseCharacter = '/characters/me/choose';
  static const String characterMoodState = '/characters/me/mood-state';

  // Achievement Endpoints
  static const String achievements = '/achievements';
  static const String myAchievements = '/achievements/me/achievements';
  static const String checkAchievements = '/achievements/me/check';
  static const String myStreak = '/achievements/me/streak';

  // Reward Endpoints
  static const String rewards = '/rewards';
  static const String myRewards = '/rewards/me/rewards';
  static const String availableRewards = '/rewards/me/available';
  static const String unlockReward = '/rewards/me/unlock';
  static const String equipReward = '/rewards/me/equip';
  static const String equippedRewards = '/rewards/me/equipped';
  static const String collectionStats = '/rewards/me/collection-stats';

  // Interest Endpoints
  static const String interests = '/interests';
  static const String popularInterests = '/interests/popular';

  // Timeouts - Increased for better reliability
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ==================== Helper Methods ====================

  /// Print current configuration for debugging
  static void printConfig() {
    print('🔧 API Configuration:');
    print('   Base URL: $baseUrl');
    print('   Connect Timeout: ${connectTimeout.inSeconds}s');
    print('   Receive Timeout: ${receiveTimeout.inSeconds}s');
  }

  /// Test if backend is reachable
  static Future<bool> testConnection() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
