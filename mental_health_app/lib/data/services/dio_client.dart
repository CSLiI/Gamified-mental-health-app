import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
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
          }
          print('📤 REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('   Message: ${error.message}');
          
          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            // Token expired or invalid - clear it
            await _storage.delete(key: 'auth_token');
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Auth Methods
  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post(ApiConstants.register, data: data);
  }

  Future<Response> login(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: data,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    
    // Save token
    if (response.data['access_token'] != null) {
      await _storage.write(
        key: 'auth_token',
        value: response.data['access_token'],
      );
    }
    
    return response;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
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
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
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
  // Add these methods to your lib/data/services/api_service.dart file
// Add them after the existing methods, before the closing brace

  // ==================== Characters ====================
  
  Future<List<dynamic>> getCharacters() async {
    final response = await _dio.get('/characters/');
    return response.data;
  }
  
  Future<Map<String, dynamic>> chooseCharacter(int characterId) async {
    final response = await _dio.post('/characters/me/choose/$characterId');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getCurrentCharacter() async {
    final response = await _dio.get('/characters/me/current');
    return response.data;
  }
  
  // Update the existing getCharacterMoodState if it's not there
  Future<Map<String, dynamic>> getCharacterMoodState() async {
    final response = await _dio.get('/characters/me/mood-state');
    return response.data;
  }
  
  // ==================== Interests ====================
  
  Future<List<dynamic>> getAllInterests() async {
    final response = await _dio.get('/interests/');
    return response.data;
  }
  
  Future<Map<String, dynamic>> addUserInterest(int interestId) async {
    final response = await _dio.post('/users/me/interests/$interestId');
    return response.data;
  }
  
  // ==================== Rewards ====================
  
  Future<List<dynamic>> getAvailableRewards() async {
    final response = await _dio.get('/rewards/me/available');
    return response.data;
  }
  
  Future<Map<String, dynamic>> unlockReward(int rewardId) async {
    final response = await _dio.post('/rewards/me/unlock/$rewardId');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getCollectionStats() async {
    final response = await _dio.get('/rewards/me/collection-stats');
    return response.data;
  }
}