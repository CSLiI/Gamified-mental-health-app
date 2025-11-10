import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';

class MoodProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _currentMood;
  bool _isLoading = false;
  String? _error;

  String? get currentMood => _currentMood;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<void> loadMood() async {
    print('😊 MoodProvider: Loading mood...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _apiService.getCurrentUser();
      final userId = user['id'];

      // Try cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedMood = prefs.getString('last_selected_mood_$userId');

      if (cachedMood != null) {
        _currentMood = cachedMood;
        print('✅ MoodProvider: Loaded cached mood: $_currentMood');
        notifyListeners();
        // Update from backend in background
        _updateFromBackend(userId);
      } else {
        // Fetch from backend
        final recentMoods = await _apiService.getMoodLogs(limit: 1);
        if (recentMoods.isNotEmpty) {
          _currentMood = recentMoods[0]['mood'] as String;
          await prefs.setString('last_selected_mood_$userId', _currentMood!);
          print('✅ MoodProvider: Loaded mood from backend: $_currentMood');
        } else {
          print('ℹ️ MoodProvider: No mood logs found');
        }
      }
    } catch (e) {
      _error = e.toString();
      print('❌ MoodProvider: Error loading mood: $e');
    } finally {
      _isLoading = false;
      print('✅ MoodProvider: Loading complete, isLoading = $_isLoading');
      notifyListeners();
    }
  }

  Future<void> updateMood(String mood) async {
    try {
      final user = await _apiService.getCurrentUser();
      final userId = user['id'];

      // Update local state immediately
      _currentMood = mood;
      notifyListeners();

      // Persist to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mood_$userId', mood);

      print('✅ MoodProvider: Mood updated to $mood');
    } catch (e) {
      _error = e.toString();
      print('Error updating mood: $e');
      notifyListeners();
    }
  }

  Future<void> _updateFromBackend(int userId) async {
    try {
      final recentMoods = await _apiService.getMoodLogs(limit: 1);
      if (recentMoods.isNotEmpty) {
        final latestMood = recentMoods[0]['mood'] as String;

        if (_currentMood != latestMood) {
          _currentMood = latestMood;
          notifyListeners();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_selected_mood_$userId', latestMood);
        }
      }
    } catch (e) {
      print('Error updating from backend: $e');
    }
  }
}
