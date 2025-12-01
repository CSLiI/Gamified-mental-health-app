import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/router/navigation_service.dart';
import 'cache_service.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _defaultConnectTimeout = Duration(seconds: 8);
  static const _defaultReceiveTimeout = Duration(seconds: 12);
  // Circuit-breaker: track recent failures per path
  final Map<String, int> _failureCounts = {};
  final Map<String, DateTime> _openUntil = {};
  static const int _failureThreshold = 3; // failures before opening breaker
  static const Duration _cooldown = Duration(seconds: 20); // open window
  static const int _maxRetries = 2; // retry attempts for transient failures
  static const int _initialRetryDelayMs =
      400; // base delay for exponential backoff

  // De-dup in-flight GETs to avoid duplicate concurrent requests
  final Map<String, Future<Response>> _inflightGet = {};

  // Global concurrency limiter for GETs to avoid flooding backend
  // Set to 2 to be conservative with backend pool (size 8 + overflow 3 = 11 max)
  // Auth cache on backend reduces DB load significantly
  static const int _maxConcurrentGets = 2;
  int _activeGets = 0;
  final List<Completer<void>> _getWaiters = [];

  Future<void> _acquireGetPermit() async {
    if (_activeGets < _maxConcurrentGets) {
      _activeGets++;
      return;
    }
    final c = Completer<void>();
    _getWaiters.add(c);
    await c.future;
    _activeGets++;
  }

  void _releaseGetPermit() {
    _activeGets = (_activeGets - 1).clamp(0, _maxConcurrentGets);
    if (_getWaiters.isNotEmpty) {
      final next = _getWaiters.removeAt(0);
      if (!next.isCompleted) next.complete();
    }
  }

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout ?? _defaultConnectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout ?? _defaultReceiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to requests
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token added to request: ${token.substring(0, 20)}...');
          } else {
            print('⚠️ No token found in storage');
          }
          print('📤 REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Ensure message is populated for cleaner UI
          if (error.message == null || error.message!.isEmpty) {
            error = DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              message: error.error?.toString() ?? 'Request failed',
            );
          }

          // Record failure for circuit-breaker
          final p = error.requestOptions.path;
          _failureCounts[p] = (_failureCounts[p] ?? 0) + 1;
          if ((_failureCounts[p] ?? 0) >= _failureThreshold) {
            _openUntil[p] = DateTime.now().add(_cooldown);
          }
          print(
              '❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('   Message: ${error.message}');

          // Simple exponential backoff for transient errors
          final requestOptions = error.requestOptions;
          final shouldRetry = _shouldRetry(error);
          final retries = (requestOptions.extra['retries'] as int?) ?? 0;
          if (shouldRetry && retries < _maxRetries) {
            final delayMs =
                _initialRetryDelayMs * (1 << retries); // 400ms, 800ms
            await Future.delayed(Duration(milliseconds: delayMs));
            requestOptions.extra['retries'] = retries + 1;
            try {
              final clone = await _dio.fetch(requestOptions);
              return handler.resolve(clone);
            } catch (e) {
              // fall through to normal error handling
            }
          }

          // Handle 401 Unauthorized more gracefully
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            print('🚨 401 Unauthorized on $path');

            // Friend endpoints may intermittently return 401 due to permissions;
            // do NOT invalidate the whole session for these.
            final isFriendEndpoint = path.startsWith('/users/') &&
                (path.contains('/profile') ||
                    path.contains('/mood-logs') ||
                    path.contains('/character/mood-state'));

            if (isFriendEndpoint) {
              // Soft-fail: keep token, let UI handle a warning gracefully.
              print('ℹ️ Friend endpoint unauthorized; keeping session intact.');
            } else {
              // For core auth endpoints, treat as session invalidation.
              print('🔑 Core endpoint unauthorized; clearing session.');
              await _storage.delete(key: 'auth_token');

              final context = NavigationService.navigatorKey.currentContext;
              if (context != null) {
                print('🔄 Redirecting to login screen...');
                GoRouter.of(context).go('/login');
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Fast-path cached GET for JSON endpoints.
  /// Returns cached data immediately if available, then refreshes in background.
  Future<Map<String, dynamic>> getCachedJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cacheKey,
    Duration maxAge = const Duration(seconds: 20),
  }) async {
    final key = cacheKey ?? _buildCacheKey(path, queryParameters);
    final cached = await CacheService().get<Map<String, dynamic>>(
      key,
      maxAge: maxAge,
    );

    // If we have cached data, refresh it in the background for next time.
    if (cached != null) {
      _refreshJsonCache(key, path, queryParameters);
    }

    if (cached != null) {
      return cached;
    }

    // Fallback to live fetch if no cache
    final resp = await get(path, queryParameters: queryParameters);
    final data = Map<String, dynamic>.from(resp.data ?? {});
    await CacheService().set(key, data);
    return data;
  }

  Future<void> _refreshJsonCache(
    String cacheKey,
    String path,
    Map<String, dynamic>? queryParameters,
  ) async {
    try {
      final resp = await get(path, queryParameters: queryParameters);
      final data = Map<String, dynamic>.from(resp.data ?? {});
      await CacheService().set(cacheKey, data);
    } catch (_) {
      // Silently ignore refresh errors
    }
  }

  String _buildCacheKey(String path, Map<String, dynamic>? qp) {
    if (qp == null || qp.isEmpty) return 'GET::$path';
    final sorted = Map<String, dynamic>.fromEntries(
      qp.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return 'GET::$path?${sorted.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  // Auth Methods
  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post(ApiConstants.register, data: data);
  }

  Future<Response> login(Map<String, dynamic> data) async {
    print('🔐 Attempting login...');

    final response = await _dio.post(
      ApiConstants.login,
      data: data,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    print('✅ Login response received');
    print('📦 Response data: ${response.data}');

    // Save token
    if (response.data['access_token'] != null) {
      final token = response.data['access_token'];
      await _storage.write(
        key: 'auth_token',
        value: token,
      );
      print('💾 Token saved: ${token.substring(0, 20)}...');

      // Verify token was saved
      final savedToken = await _storage.read(key: 'auth_token');
      if (savedToken != null) {
        print('✅ Token verified in storage');
      } else {
        print('❌ Token NOT saved to storage!');
      }
    } else {
      print('⚠️ No access_token in response!');
    }

    return response;
  }

  Future<void> logout() async {
    // Clear auth token
    await _storage.delete(key: 'auth_token');

    // Clear API Cache (Critical for data privacy between users)
    await CacheService().clearAll();

    // Clear ALL user-specific SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    // Remove all keys that might contain user-specific data
    for (final key in keys) {
      if (key.contains('selected_character_') ||
          key.contains('last_selected_mood_') ||
          key.contains('_user_')) {
        await prefs.remove(key);
        print('🧹 Removed SharedPreferences key: $key');
      }
    }

    // Also remove old non-user-specific keys for backward compatibility
    await prefs.remove('selected_character_id');
    await prefs.remove('selected_character_gender');
    await prefs.remove('selected_character_number');
    await prefs.remove('last_selected_mood');

    print('🚪 Token and ALL user data deleted - logged out');
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      print('🔑 Token retrieved: ${token.substring(0, 20)}...');
    } else {
      print('❌ No token in storage');
    }
    return token;
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _acquireGetPermit();
    // Circuit breaker: if open, short-circuit to avoid hammering backend
    final open = _openUntil[path];
    if (open != null && DateTime.now().isBefore(open)) {
      _releaseGetPermit();
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.unknown,
        message: 'Service temporarily unavailable for $path (cooling down)',
      );
    }

    final inflightKey = _buildCacheKey(path, queryParameters);
    final existing = _inflightGet[inflightKey];
    if (existing != null) {
      return existing;
    }

    final future = _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    _inflightGet[inflightKey] = future;
    try {
      final resp = await future;
      // Reset failure count on success
      _failureCounts[path] = 0;
      _openUntil.remove(path);
      return resp;
    } finally {
      _inflightGet.remove(inflightKey);
      _releaseGetPermit();
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

bool _shouldRetry(DioException error) {
  // Retry on timeouts and 5xx server errors
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.badCertificate) {
    return true;
  }
  final status = error.response?.statusCode ?? 0;
  return status >= 500 && status != 501; // avoid retrying not implemented
}
