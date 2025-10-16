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
            print('🔑 Token added to request: ${token.substring(0, 20)}...');
          } else {
            print('⚠️ No token found in storage');
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
            print('🚨 401 Unauthorized - Token may be invalid or expired');
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
    await _storage.delete(key: 'auth_token');
    print('🚪 Token deleted - logged out');
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
}