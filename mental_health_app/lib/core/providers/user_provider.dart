import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';

/// Singleton provider for current user data to prevent redundant API calls.
///
/// This provider acts as a single source of truth for the authenticated user,
/// reducing duplicate API calls across the app. Other providers should inject
/// this provider to access userId rather than calling getCurrentUser() directly.
class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

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
      print('✅ UserProvider: Loaded user ${_user?['id']}');
    } catch (e) {
      _error = e.toString();
      print('❌ UserProvider: Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data (force fetch from API)
  Future<void> refreshUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.getCurrentUser();
      print('✅ UserProvider: Refreshed user ${_user?['id']}');
    } catch (e) {
      _error = e.toString();
      print('❌ UserProvider: Error refreshing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear user data (on logout)
  @visibleForTesting
  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }
}
