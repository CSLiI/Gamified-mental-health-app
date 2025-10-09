class ApiConstants {
  // Base URL - Change this to your computer's IP when testing on physical device
  // Use 'localhost' or '127.0.0.1' for emulator
  // Use your computer's IP (e.g., '192.168.1.x') for physical device
  static const String baseUrl = 'http://localhost:8000';
  
  // For Android Emulator, use: 'http://10.0.2.2:8000'
  // For iOS Simulator, use: 'http://localhost:8000'
  // For Physical Device, use: 'http://YOUR_IP:8000'
  
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
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}