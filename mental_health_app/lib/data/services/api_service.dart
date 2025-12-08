import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'dio_client.dart';
import 'cache_service.dart';

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
      // print('🔐 ApiService: Starting login process...');

      final response = await _dioClient.login({
        'username': email,
        'password': password,
      });

      // print('✅ ApiService: Login successful');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // print('❌ ApiService: Login failed - ${e.message}');
      throw _handleError(e);
    }
  }

  // ==================== User ====================

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Use cached GET helper for immediate data + background refresh
      final json = await _dioClient.getCachedJson(
        ApiConstants.me,
        cacheKey: CacheKeys.userProfile,
        maxAge: CacheService.mediumCache,
      );
      return json as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get fresh user data bypassing cache - use for XP/level critical displays
  Future<Map<String, dynamic>> getFreshUserData() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      // Also update the cache with fresh data
      await CacheService().set(CacheKeys.userProfile, response.data);
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
      final json = await _dioClient.getCachedJson(
        ApiConstants.characterMoodState,
        cacheKey: CacheKeys.characterMoodState,
        maxAge: CacheService.shortCache,
      );
      return json as Map<String, dynamic>;
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
      final response = await _dioClient.get(ApiConstants.myRewards);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getEquippedRewards() async {
    try {
      final response = await _dioClient.get(ApiConstants.equippedRewards);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> equipReward(int rewardId) async {
    try {
      await _dioClient.post('${ApiConstants.equipReward}/$rewardId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unequipReward(int rewardId) async {
    try {
      await _dioClient.delete('${ApiConstants.equipReward}/$rewardId');
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

  // ==================== Daily Rewards ====================
  Future<Map<String, dynamic>> getDailyStatus() async {
    try {
      final response = await _dioClient.get(ApiConstants.dailyStatus);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      final response = await _dioClient.post(ApiConstants.dailyClaim);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDailyCalendar({int days = 30}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.dailyCalendar,
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStreakFreezeStatus() async {
    try {
      final response = await _dioClient.get(ApiConstants.streakFreeze);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> useStreakFreeze() async {
    try {
      final response = await _dioClient.post(ApiConstants.useStreakFreeze);
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
      // Note: Can't use getCachedJson since this returns a List, not a Map
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
      final json = await _dioClient.getCachedJson(
        '/users/$userId/profile',
        // Scope cache per user
        cacheKey: 'friend_profile_$userId',
        maxAge: CacheService.shortCache,
      );
      return json as Map<String, dynamic>;
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
      final json = await _dioClient.getCachedJson(
        '/users/$userId/character/mood-state',
        queryParameters: {'days': days},
        cacheKey: 'friend_mood_state_${userId}_d$days',
        maxAge: CacheService.shortCache,
      );
      return json as Map<String, dynamic>;
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

  // ==================== Quest System ====================
  Future<Map<String, dynamic>> getActiveQuests() async {
    try {
      final response = await _dioClient.get(ApiConstants.questsActive);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateDailyQuests(
      {bool forceRefresh = false}) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.questsDailyGenerate,
        queryParameters: {'force_refresh': forceRefresh},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateWeeklyQuests() async {
    try {
      final response = await _dioClient.post(ApiConstants.questsWeeklyGenerate);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateQuestProgress(String category,
      {int increment = 1}) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.questsProgress}/$category',
        queryParameters: {'increment': increment},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Manually complete a quest (for activities done outside the app)
  Future<Map<String, dynamic>> completeQuest(int questId) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.questsBase}/$questId/complete',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Increment quest progress by amount (for multi-step quests)
  Future<Map<String, dynamic>> incrementQuestProgress(int questId,
      {int amount = 1}) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.questsBase}/$questId/increment',
        queryParameters: {'amount': amount},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Level System ====================
  Future<Map<String, dynamic>> checkLevelUp() async {
    try {
      final response = await _dioClient.get(ApiConstants.levelCheck);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLevelProgress() async {
    try {
      final response = await _dioClient.get(ApiConstants.levelProgress);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  // ==================== Mystery Boxes ====================
  Future<Map<String, dynamic>> getUnopenedBoxes() async {
    try {
      final response = await _dioClient.get(ApiConstants.mysteryBoxes);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> openMysteryBox(int boxId) async {
    try {
      final response =
          await _dioClient.post('${ApiConstants.mysteryBoxOpen}/$boxId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Comeback Rewards ====================
  Future<Map<String, dynamic>> checkComebackReward() async {
    try {
      final response = await _dioClient.get(ApiConstants.comebackCheck);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Tiered Rewards ====================
  Future<Map<String, dynamic>> getAllTiers() async {
    try {
      final response = await _dioClient.get(ApiConstants.rewardsTiers);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRewardsByTier(int tier) async {
    try {
      final response =
          await _dioClient.get('${ApiConstants.rewardsByTier}/$tier');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  // ==================== Builtin Rewards ====================
  Future<Map<String, dynamic>> getBuiltinRewardsData() async {
    try {
      final response = await _dioClient.get('/builtin-rewards/me/data');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> purchaseBuiltinReward(
      int rewardId, String category, int xpCost) async {
    try {
      final response = await _dioClient.post(
        '/builtin-rewards/me/purchase',
        data: {
          'reward_id': rewardId,
          'category': category,
          'xp_cost': xpCost,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> equipBuiltinReward(
      int rewardId, String category) async {
    try {
      final response = await _dioClient.post(
        '/builtin-rewards/me/equip',
        data: {
          'reward_id': rewardId,
          'category': category,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unequipBuiltinReward(int rewardId) async {
    try {
      await _dioClient.delete('/builtin-rewards/me/unequip/$rewardId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> syncBuiltinRewards(
      List<dynamic> purchased, List<dynamic> equipped, int xpSpent) async {
    try {
      await _dioClient.post(
        '/builtin-rewards/me/sync',
        data: {
          'purchased': purchased,
          'equipped': equipped,
          'xp_spent': xpSpent,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  // ==================== Pets ====================

  Future<List<dynamic>> getPetCatalog() async {
    try {
      final response = await _dioClient.get('${ApiConstants.baseUrl}/pets/catalog');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyPets() async {
    try {
      final response = await _dioClient.get('${ApiConstants.baseUrl}/pets/my-pets');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> unlockPet(int petId) async {
    try {
      final response = await _dioClient.post('${ApiConstants.baseUrl}/pets/unlock/$petId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> equipPet(int petId) async {
    try {
      final response = await _dioClient.post('${ApiConstants.baseUrl}/pets/equip/$petId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> interactWithPet() async {
    try {
      final response = await _dioClient.post('${ApiConstants.baseUrl}/pets/interact');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> feedPet() async {
    try {
      final response = await _dioClient.post('${ApiConstants.baseUrl}/pets/feed');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> renamePet(int petId, String name) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.baseUrl}/pets/$petId/rename',
        queryParameters: {'name': name},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
