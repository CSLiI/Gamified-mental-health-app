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

  Future<void> deleteMoodLog(int moodId) async {
    try {
      await _dioClient.delete('${ApiConstants.moods}/$moodId');
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

  Future<List<dynamic>> getJournalEntries({int? skip, int? limit}) async {
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

  Future<List<dynamic>> getAllAchievements() async {
    try {
      final response = await _dioClient.get('${ApiConstants.achievements}/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserAchievements() async {
    try {
      final response = await _dioClient.get(ApiConstants.myAchievements);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  Future<List<dynamic>> getAllRewards() async {
    try {
      final response = await _dioClient.get('${ApiConstants.rewards}/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserRewards() async {
    try {
      final response = await _dioClient.get('${ApiConstants.rewards}/me');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getEquippedRewards() async {
    try {
      final response =
          await _dioClient.get('${ApiConstants.rewards}/me/equipped');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> equipReward(int rewardId) async {
    try {
      await _dioClient.post('${ApiConstants.rewards}/$rewardId/equip');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await _dioClient.get(
        '/friends/search',
        queryParameters: {'query': query},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendFriendRequest(String email) async {
    try {
      await _dioClient.post(
        '/friends/request',
        data: {'receiver_email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getFriends() async {
    try {
      final response = await _dioClient.get('/friends/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getReceivedFriendRequests() async {
    try {
      final response = await _dioClient.get('/friends/requests/received');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getSentFriendRequests() async {
    try {
      final response = await _dioClient.get('/friends/requests/sent');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> acceptFriendRequest(int requestId) async {
    try {
      await _dioClient.put('/friends/request/$requestId/accept');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> rejectFriendRequest(int requestId) async {
    try {
      await _dioClient.put('/friends/request/$requestId/reject');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelFriendRequest(int requestId) async {
    try {
      await _dioClient.delete('/friends/request/$requestId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFriend(int friendId) async {
    try {
      await _dioClient.delete('/friends/$friendId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get friend's profile including character
  Future<Map<String, dynamic>> getFriendProfile(int userId) async {
    try {
      final response = await _dioClient.get('/users/$userId/profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get friend's todos
  Future<List<dynamic>> getFriendTodos(int userId, {String? periodType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodType != null) queryParams['period_type'] = periodType;

      final response = await _dioClient.get(
        '/users/$userId/todos',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get friend's streak
  Future<Map<String, dynamic>> getFriendStreak(int userId) async {
    try {
      final response = await _dioClient.get('/users/$userId/streak');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get friend's character mood state
  Future<Map<String, dynamic>> getFriendCharacterMoodState(int userId,
      {int days = 7}) async {
    try {
      print('[DEBUG API] Fetching mood state for friend userId: $userId');
      final response = await _dioClient.get(
        '/users/$userId/character/mood-state',
        queryParameters: {'days': days},
      );
      print(
          '[DEBUG API] Received mood state for user $userId: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get friend's mood logs for chart
  Future<List<dynamic>> getFriendMoodLogs(int userId, {int days = 7}) async {
    try {
      final response = await _dioClient.get(
        '/users/$userId/mood-logs',
        queryParameters: {'days': days},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send encouragement to friend
  Future<void> sendEncouragement(int friendId, String message) async {
    try {
      await _dioClient.post(
        '/friends/$friendId/encouragement',
        data: {'message': message},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get encouragements received
  Future<List<dynamic>> getEncouragements({bool? unreadOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _dioClient.get(
        '/encouragements/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mark encouragement as read
  Future<void> markEncouragementRead(int encouragementId) async {
    try {
      await _dioClient.put('/encouragements/$encouragementId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get all messages (challenges) received from all friends
  Future<List<dynamic>> getAllReceivedMessages({bool? unreadOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _dioClient.get(
        '/messages/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send message to friend
  Future<void> sendMessage(int friendId, String message) async {
    try {
      await _dioClient.post(
        '/friends/$friendId/messages',
        data: {'message': message},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get messages with friend
  Future<List<dynamic>> getMessages(int friendId) async {
    try {
      final response = await _dioClient.get('/friends/$friendId/messages');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update message completion status (for challenges)
  Future<void> updateMessageCompletion(int messageId, bool isCompleted) async {
    try {
      await _dioClient.put(
        '/messages/$messageId/completion',
        data: {'is_completed': isCompleted},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
