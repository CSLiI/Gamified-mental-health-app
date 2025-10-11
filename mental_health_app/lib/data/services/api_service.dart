// lib/data/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // Use 'http://localhost:8000' for iOS simulator
  // Use 'http://YOUR_IP:8000' for physical device
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  final _storage = const FlutterSecureStorage();
  String? _token;
  
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }
  
  // ==================== Authentication ====================
  
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? dateOfBirth,
    String? gender,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password_hash': password,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final formData = FormData.fromMap({
      'username': email,
      'password': password,
    });
    
    final response = await _dio.post('/auth/login', data: formData);
    
    _token = response.data['access_token'];
    await _storage.write(key: 'token', value: _token);
    
    return response.data;
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }
  
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'token');
  }
  
  Future<void> loadToken() async {
    _token = await _storage.read(key: 'token');
  }
  
  // ==================== User ====================
  
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }
  
  Future<List<dynamic>> getUserInterests() async {
    final response = await _dio.get('/users/me/interests');
    return response.data;
  }
  
  // ==================== Moods ====================
  
  Future<Map<String, dynamic>> logMood({
    required String mood,
    String? note,
  }) async {
    final response = await _dio.post('/moods/', data: {
      'mood': mood,
      'note': note,
    });
    return response.data;
  }
  
  Future<List<dynamic>> getMoodLogs() async {
    final response = await _dio.get('/moods/');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getMoodStatistics() async {
    final response = await _dio.get('/moods/statistics');
    return response.data;
  }
  
  // ==================== Journals ====================
  
  Future<Map<String, dynamic>> createJournalEntry({
    String? title,
    required String content,
  }) async {
    final response = await _dio.post('/journals/', data: {
      'title': title,
      'content': content,
    });
    return response.data;
  }
  
  Future<List<dynamic>> getJournalEntries() async {
    final response = await _dio.get('/journals/');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getDailyPrompt() async {
    final response = await _dio.get('/journal-prompts/daily');
    return response.data;
  }
  
  // ==================== Todos ====================
  
  Future<Map<String, dynamic>> createTodo(String taskText) async {
    final response = await _dio.post('/todos/', data: {
      'task_text': taskText,
      'is_completed': false,
    });
    return response.data;
  }
  
  Future<List<dynamic>> getTodos({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get('/todos/', queryParameters: {
      'skip': skip,
      'limit': limit,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> completeTodo(int todoId) async {
    final response = await _dio.post('/todos/$todoId/complete');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getTodoStatistics() async {
    final response = await _dio.get('/todos/statistics');
    return response.data;
  }
  
  // ==================== Characters ====================
  
  Future<Map<String, dynamic>> getCharacterMoodState() async {
    final response = await _dio.get('/characters/me/mood-state');
    return response.data;
  }
  
  // ==================== Achievements ====================
  
  Future<List<dynamic>> getUserAchievements() async {
    final response = await _dio.get('/achievements/me/achievements');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getStreak() async {
    final response = await _dio.get('/achievements/me/streak');
    return response.data;
  }
}