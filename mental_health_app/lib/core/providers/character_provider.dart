import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import 'user_provider.dart';

class CharacterProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final UserProvider _userProvider;

  int? _characterId;
  String? _characterGender;
  int? _characterNumber;
  bool _isLoading = false;
  String? _error;

  CharacterProvider(this._userProvider);

  int get characterId => _characterId ?? 1;
  String get characterGender => _characterGender ?? 'Boy';
  int get characterNumber => _characterNumber ?? 1;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCharacter() async {
    print('🎭 CharacterProvider: Loading character...');
    if (_isLoading) return; // Prevent duplicate calls

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try API first
      final currentCharacter = await _apiService.getCurrentCharacter();

      if (currentCharacter['character'] != null) {
        final character = currentCharacter['character'];
        _characterId = character['id'];
        _characterGender = character['gender'];
        _characterNumber = character['number'];

        print(
            '✅ CharacterProvider: Loaded character from API - $_characterGender $_characterNumber');

        // Cache the values using userId from UserProvider
        final userId = _userProvider.userId;
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('selected_character_id_$userId', _characterId!);
          await prefs.setString(
              'selected_character_gender_$userId', _characterGender!);
          await prefs.setInt(
              'selected_character_number_$userId', _characterNumber!);
        }

        _isLoading = false;
        print('✅ CharacterProvider: Loading complete, isLoading = $_isLoading');
        notifyListeners();
        return;
      }
    } catch (e) {
      print('⚠️ CharacterProvider: Error loading from API: $e');
    }

    // Fallback to cache
    try {
      final userId = _userProvider.userId;
      if (userId == null) {
        throw Exception('User not loaded yet');
      }
      final prefs = await SharedPreferences.getInstance();

      _characterId = prefs.getInt('selected_character_id_$userId') ?? 1;
      _characterGender =
          prefs.getString('selected_character_gender_$userId') ?? 'Boy';
      _characterNumber = prefs.getInt('selected_character_number_$userId') ?? 1;
    } catch (e) {
      _error = e.toString();
      print('Error loading character: $e');
      // Use defaults
      _characterId = 1;
      _characterGender = 'Boy';
      _characterNumber = 1;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCharacter(int id, String gender, int number) async {
    _characterId = id;
    _characterGender = gender;
    _characterNumber = number;
    notifyListeners();

    try {
      final userId = _userProvider.userId;
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selected_character_id_$userId', id);
        await prefs.setString('selected_character_gender_$userId', gender);
        await prefs.setInt('selected_character_number_$userId', number);
      }
    } catch (e) {
      _error = e.toString();
      print('Error updating character: $e');
    }
  }
}
