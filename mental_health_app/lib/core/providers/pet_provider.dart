import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';

class PetProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _catalog = [];
  List<dynamic> _myPets = [];
  Map<String, dynamic>? _activePet;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get catalog => _catalog;
  List<dynamic> get myPets => _myPets;
  Map<String, dynamic>? get activePet => _activePet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<List<dynamic>>([
        _apiService.getPetCatalog(),
        _apiService.getMyPets(),
      ]);

      _catalog = results[0];
      _myPets = results[1];

      // Find active pet
      _activePet = _myPets.firstWhere(
        (pet) => pet['is_active'] == true,
        orElse: () => null,
      );
      print('✅ PetProvider: Loaded ${_myPets.length} pets. Active: ${_activePet?['name']}');
    } catch (e) {
      _error = e.toString();
      print('❌ PetProvider: Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unlockPet(int petId) async {
    try {
      final result = await _apiService.unlockPet(petId);
      if (result['success'] == true) {
        // Refresh my pets to show the new one
        final newPets = await _apiService.getMyPets();
        _myPets = newPets;
        notifyListeners();
      }
    } catch (e) {
      print('❌ PetProvider: Error unlocking pet: $e');
      rethrow;
    }
  }

  Future<void> equipPet(int petId) async {
    try {
      final result = await _apiService.equipPet(petId);
      if (result['success'] == true) {
        // Update local state
        _activePet = result['active_pet'];
        
        // Update myPets list to reflect active status
        _myPets = _myPets.map((pet) {
          if (pet['id'] == petId) {
            return {...pet, 'is_active': true};
          } else {
            return {...pet, 'is_active': false};
          }
        }).toList();
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ PetProvider: Error equipping pet: $e');
      rethrow;
    }
  }

  Future<int> interact() async {
    if (_activePet == null) return 0;
    
    try {
      final result = await _apiService.interactWithPet();
      if (result['success'] == true) {
        final affectionGained = result['affection_gained'] as int;
        
        // Update local affection
        if (_activePet != null) {
          final currentAffection = _activePet!['affection_level'] as int;
          _activePet!['affection_level'] = currentAffection + affectionGained;
          notifyListeners();
        }
        
        return affectionGained;
      }
      return 0;
    } catch (e) {
      print('❌ PetProvider: Error interacting with pet: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> feed() async {
    if (_activePet == null) return {'success': false};

    try {
      final result = await _apiService.feedPet();
      if (result['success'] == true) {
        final newHunger = result['new_hunger'] as int;

        // Update local state
        if (_activePet != null) {
          _activePet!['hunger'] = newHunger;
          // Also affection increases by 1
          final currentAffection = _activePet!['affection_level'] as int;
          if (currentAffection < 100) {
            _activePet!['affection_level'] = currentAffection + 1;
          }
          notifyListeners();
        }

        return result;
      }
      return {'success': false};
    } catch (e) {
      print('❌ PetProvider: Error feeding pet: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> renamePet(int petId, String newName) async {
    try {
      final result = await _apiService.renamePet(petId, newName);
      if (result['success'] == true) {
        // Update active pet if it's the one being renamed
        if (_activePet != null && _activePet!['id'] == petId) {
          _activePet!['name'] = newName;
        }
        
        // Update myPets list
        _myPets = _myPets.map((pet) {
          if (pet['id'] == petId) {
            return {...pet, 'name': newName};
          }
          return pet;
        }).toList();
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ PetProvider: Error renaming pet: $e');
      return false;
    }
  }

  void clear() {
    _catalog = [];
    _myPets = [];
    _activePet = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
