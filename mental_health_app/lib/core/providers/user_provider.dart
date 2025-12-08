import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/api_service.dart';
import '../constants/storage_keys.dart';

/// Singleton provider for current user data to prevent redundant API calls.
///
/// This provider acts as a single source of truth for the authenticated user,
/// reducing duplicate API calls across the app. Other providers should inject
/// this provider to access userId rather than calling getCurrentUser() directly.
class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  int? get userId => _user?['id'] as int?;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Load user data (with built-in caching via ApiService)
  Future<void> loadUser() async {
    if (_isLoading) return; // Prevent duplicate concurrent calls
    if (_user != null) return; // Already loaded

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.getCurrentUser();
      print('✅ UserProvider: Loaded user ${_user?['id']} - Energy: ${_user?['energy']}');

      // Store user ID for user-specific storage
      if (_user?['id'] != null) {
        await _secureStorage.write(
          key: StorageKeys.currentUserId,
          value: _user!['id'].toString(),
        );
      }
    } catch (e) {
      _error = e.toString();
      print('❌ UserProvider: Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data (force fetch from API, bypass cache)
  Future<void> refreshUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use getFreshUserData to bypass cache and get latest energy value
      _user = await _apiService.getFreshUserData();
      print('✅ UserProvider: Refreshed user ${_user?['id']} - Energy: ${_user?['energy']}');

      // Store user ID for user-specific storage
      if (_user?['id'] != null) {
        await _secureStorage.write(
          key: StorageKeys.currentUserId,
          value: _user!['id'].toString(),
        );
      }
    } catch (e) {
      _error = e.toString();
      print('❌ UserProvider: Error refreshing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data after an action (with delay to ensure backend commit completes)
  /// Use this after completing tasks, quests, or pet actions
  Future<void> refreshUserAfterAction() async {
    // Small delay to ensure backend database commit has finished
    await Future.delayed(const Duration(milliseconds: 200));
    await refreshUser();
  }

  /// Clear user data (on logout)
  @visibleForTesting
  Future<void> clearUser() async {
    _user = null;
    _error = null;
    // Clear stored user ID
    await _secureStorage.delete(key: StorageKeys.currentUserId);
    notifyListeners();
  }
}
