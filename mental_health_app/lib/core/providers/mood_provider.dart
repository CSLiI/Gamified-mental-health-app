import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../constants/storage_keys.dart';
import 'user_provider.dart';

class MoodProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final UserProvider _userProvider;

  String? _currentMood;
  double? _moodScore;
  String? _characterState;
  bool _isLoading = false;
  String? _error;

  MoodProvider(this._userProvider);

  String? get currentMood => _currentMood;
  double get moodScore => _moodScore ?? 50.0;
  String get characterState => _characterState ?? 'content';
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Track if we've shown the care alert this session to prevent spam
  bool _hasShownLowMoodAlert = false;
  bool get hasShownLowMoodAlert => _hasShownLowMoodAlert;
  
  void markLowMoodAlertShown() {
    _hasShownLowMoodAlert = true;
    notifyListeners();
  }

  // Mood color mapping
  final Map<String, Color> _moodColors = {
    'happy': const Color(0xFFFFD54F),
    'calm': const Color(0xFF42A5F5),
    'tired': const Color(0xFF78909C),
    'anxious': const Color(0xFFFFA726),
    'sad': const Color(0xFF9575CD),
    'angry': const Color(0xFFEF5350),
  };

  Color getMoodColor([String? mood]) {
    final moodToUse = mood ?? _currentMood;
    if (moodToUse != null && _moodColors.containsKey(moodToUse)) {
      return _moodColors[moodToUse]!;
    }
    return const Color(0xFF5CACEE);
  }

  Future<void> loadMood({bool forceRefresh = false}) async {
    print('😊 MoodProvider: Loading mood...');
    
    // Allow re-loading even if already loading (for real-time updates)
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _userProvider.userId;
      if (userId == null) {
        print('⚠️ MoodProvider: No user loaded yet');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Always fetch fresh data from backend for real-time updates
      try {
        final results = await Future.wait([
          _apiService.getMoodLogs(limit: 1),
          _apiService.getCharacterMoodState(forceRefresh: forceRefresh),
        ]);

        final recentMoods = results[0] as List<dynamic>;
        final moodState = results[1] as Map<String, dynamic>;

        if (recentMoods.isNotEmpty) {
          _currentMood = recentMoods[0]['mood'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              StorageKeys.lastSelectedMood(userId), _currentMood!);
          print('✅ MoodProvider: Loaded mood: $_currentMood');
        }
        
        if (moodState.containsKey('mood_score')) {
          _moodScore = (moodState['mood_score'] as num).toDouble();
          _characterState = moodState['character_state'] as String?;
          print('✅ MoodProvider: Loaded mood score: $_moodScore');
        }
      } catch (e) {
        print('Error loading mood data: $e');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ MoodProvider: Error loading mood: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('✅ MoodProvider: notifyListeners() called');
    }
  }

  Future<void> updateMood(String mood) async {
    try {
      final userId = _userProvider.userId;
      if (userId == null) {
        print('⚠️ MoodProvider: No user loaded for mood update');
        return;
      }

      // Update local state immediately
      _currentMood = mood;
      notifyListeners();

      // Persist to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.lastSelectedMood(userId), mood);

      print('✅ MoodProvider: Mood updated to $mood');
    } catch (e) {
      _error = e.toString();
      print('Error updating mood: $e');
      notifyListeners();
    }
  }

  Future<void> _updateFromBackend(int userId) async {
    try {
      final results = await Future.wait([
        _apiService.getMoodLogs(limit: 1),
        _apiService.getCharacterMoodState(),
      ]);

      final recentMoods = results[0] as List<dynamic>;
      final moodState = results[1] as Map<String, dynamic>;

      if (recentMoods.isNotEmpty) {
        final latestMood = recentMoods[0]['mood'] as String;
        if (_currentMood != latestMood) {
          _currentMood = latestMood;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              StorageKeys.lastSelectedMood(userId), latestMood);
        }
      }

      if (moodState.containsKey('mood_score')) {
        _moodScore = (moodState['mood_score'] as num).toDouble();
        _characterState = moodState['character_state'] as String?;
      }
      notifyListeners();
    } catch (e) {
      print('Error updating from backend: $e');
    }
  }

  /// Clear mood data on logout
  Future<void> clearMood() async {
    print('🧹 MoodProvider: Clearing mood on logout...');
    _currentMood = null;
    _moodScore = null;
    _characterState = null;
    _error = null;

    _isLoading = false;
    notifyListeners();
  }
}
