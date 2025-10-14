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
}) async {
  try {
    // Backend expects 'password_hash' field, not 'password'
    final response = await _dioClient.post(ApiConstants.register, data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password_hash': password,  // ⬅️ Backend expects this field name
    });
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
    // FastAPI OAuth2 expects form data, not JSON
    final response = await _dioClient.post(
      ApiConstants.login,
      data: {
        'username': email,  // ⬅️ OAuth2 uses 'username' field
        'password': password,
      },
      options: Options(
        contentType: 'application/x-www-form-urlencoded',  // ⬅️ Important!
      ),
    );
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
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

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
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
      final response = await _dioClient.post('${ApiConstants.chooseCharacter}/$characterId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
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
        ApiConstants.moods,
        data: moodData,
      );
      return response.data as Map<String, dynamic>;
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
  
  Future<Map<String, dynamic>> createJournal(Map<String, dynamic> journalData) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.journals,
        data: journalData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getJournals({int? skip, int? limit}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.journals,
        queryParameters: {
          if (skip != null) 'skip': skip,
          if (limit != null) 'limit': limit,
        },
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
      final response = await _dioClient.post('${ApiConstants.userInterests}/$interestId');
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
      final response = await _dioClient.post('${ApiConstants.unlockReward}/$rewardId');
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
    
    // Handle validation errors (422)
    if (error.response!.statusCode == 422 && data is Map) {
      if (data.containsKey('detail')) {
        // Extract validation error messages
        final detail = data['detail'];
        if (detail is List) {
          final errors = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
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