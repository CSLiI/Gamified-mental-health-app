import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'dio_client.dart';

class ApiService {
  final DioClient _dioClient = DioClient();

  // ==================== Auth ====================

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password_hash': password,
      };

      if (dateOfBirth != null) {
        data['date_of_birth'] = dateOfBirth;
      }

      if (gender != null) {
        data['gender'] = gender;
      }

      final response = await _dioClient.post(ApiConstants.register, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 ApiService: Starting login process...');

      final response = await _dioClient.login({
        'username': email,
        'password': password,
      });

      print('✅ ApiService: Login successful');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ ApiService: Login failed - ${e.message}');
      throw _handleError(e);
    }
  }

  // ==================== User ====================

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.users}/me',
        data: profileData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Characters ====================

  Future<List<dynamic>> getCharacters() async {
    try {
      final response = await _dioClient.get(ApiConstants.characters);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentCharacter() async {
    try {
      final response = await _dioClient.get(ApiConstants.currentCharacter);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> chooseCharacter(int characterId) async {
    try {
      print('🎯 Choosing character $characterId...');
      final response =
          await _dioClient.post('${ApiConstants.chooseCharacter}/$characterId');
      print('✅ Character chosen successfully');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Choose character failed: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCharacterMoodState() async {
    try {
      final response = await _dioClient.get(ApiConstants.characterMoodState);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Moods ====================

  Future<Map<String, dynamic>> createMood(Map<String, dynamic> moodData) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.moods}/',
        data: moodData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMoodLogs({int? skip, int? limit, int? days}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (skip != null) queryParams['skip'] = skip;
      if (limit != null) queryParams['limit'] = limit;
      if (days != null) queryParams['days'] = days;

      final response = await _dioClient.get(
        '${ApiConstants.moods}/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMoodStatistics({int? days}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.moodStatistics,
        queryParameters: days != null ? {'days': days} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Journals ====================

  Future<Map<String, dynamic>> createJournal(
      Map<String, dynamic> journalData) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.journals}/',
        data: journalData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getJournals({int? skip, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (skip != null) queryParams['skip'] = skip;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dioClient.get(
        '${ApiConstants.journals}/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDailyPrompt() async {
    try {
      final response = await _dioClient.get(ApiConstants.dailyPrompt);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateJournal(
      int journalId, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient
          .put('${ApiConstants.journals}/$journalId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteJournal(int journalId) async {
    try {
      await _dioClient.delete('${ApiConstants.journals}/$journalId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Todos ====================

  Future<Map<String, dynamic>> createTodo(Map<String, dynamic> todoData) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.todos}/',
        data: todoData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getTodos(
      {int? skip, int? limit, bool? completed, String? periodType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (skip != null) queryParams['skip'] = skip;
      if (limit != null) queryParams['limit'] = limit;
      if (completed != null) queryParams['completed'] = completed;
      if (periodType != null) queryParams['period_type'] = periodType;

      final response = await _dioClient.get(
        '${ApiConstants.todos}/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeTodo(int todoId) async {
    try {
      final response =
          await _dioClient.post('${ApiConstants.todos}/$todoId/complete');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uncompleteTodo(int todoId) async {
    try {
      final response =
          await _dioClient.post('${ApiConstants.todos}/$todoId/uncomplete');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTodo(
      int todoId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.put('${ApiConstants.todos}/$todoId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTodoStatistics() async {
    try {
      final response = await _dioClient.get(ApiConstants.todoStatistics);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTodo(int todoId) async {
    try {
      await _dioClient.delete('${ApiConstants.todos}/$todoId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Achievements ====================

  Future<List<dynamic>> getMyAchievements() async {
    try {
      final response = await _dioClient.get(ApiConstants.myAchievements);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyStreak() async {
    try {
      final response = await _dioClient.get(ApiConstants.myStreak);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkAchievements() async {
    try {
      final response = await _dioClient.post(ApiConstants.checkAchievements);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Interests ====================

  Future<List<dynamic>> getAllInterests() async {
    try {
      final response = await _dioClient.get(ApiConstants.interests);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addUserInterest(int interestId) async {
    try {
      final response =
          await _dioClient.post('${ApiConstants.userInterests}/$interestId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Rewards ====================

  Future<List<dynamic>> getAvailableRewards() async {
    try {
      final response = await _dioClient.get(ApiConstants.availableRewards);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unlockReward(int rewardId) async {
    try {
      final response =
          await _dioClient.post('${ApiConstants.unlockReward}/$rewardId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      final response = await _dioClient.get(ApiConstants.collectionStats);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

      if (error.response!.statusCode == 422 && data is Map) {
        if (data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is List) {
            final errors =
                detail.map((e) => e['msg'] ?? e.toString()).join(', ');
            return 'Validation error: $errors';
          }
          return data['detail'].toString();
        }
      }

      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    } else {
      return 'Network error: ${error.message}';
    }
  }
}
