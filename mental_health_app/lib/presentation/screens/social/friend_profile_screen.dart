import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final int friendId;
  final String friendName;

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _friendProfile;
  Map<String, dynamic>? _friendStreak;
  Map<String, dynamic>? _friendCharacterState;
  List<dynamic> _friendTodos = [];
  List<dynamic> _friendMoodLogs = [];
  List<dynamic> _friendMessages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFriendData() async {
    setState(() => _isLoading = true);
    try {
      // Get current user first to properly filter messages
      final currentUser = await _apiService.getCurrentUser();
      final currentUserId = currentUser['id'];

      final profile = await _apiService.getFriendProfile(widget.friendId);
      final streak = await _apiService.getFriendStreak(widget.friendId);
      final characterState =
          await _apiService.getFriendCharacterMoodState(widget.friendId);
      final todos = await _apiService.getFriendTodos(widget.friendId,
          periodType: 'daily');
      final moodLogs = await _apiService.getFriendMoodLogs(widget.friendId);
      final messages = await _apiService.getMessages(widget.friendId);

      print('📊 [FRIEND PROFILE DEBUG]');
      print('Current user ID: $currentUserId');
      print('Friend ID: ${widget.friendId}');
      print('Profile data: $profile');
      print('Streak data: $streak');
      print('Character state: $characterState');
      print('Character state value: ${characterState['character_state']}');
      print('Dominant mood: ${characterState['dominant_mood']}');
      print('Mood score: ${characterState['mood_score']}');
      print('Todos count: ${todos.length}');
      print('Mood logs count: ${moodLogs.length}');
      print('Messages count: ${messages.length}');
      print('Level: ${profile['level']}, XP: ${profile['xp']}');
      print('Current streak: ${profile['current_streak']}');

      if (mounted) {
        setState(() {
          _currentUserId = currentUserId;
          _friendProfile = profile;
          _friendStreak = streak;
          _friendCharacterState = characterState;
          _friendTodos = todos;
          _friendMoodLogs = moodLogs;
          _friendMessages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading friend data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCharacterGifPath(String mood, String gender, int number) {
    String moodState;
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        moodState = 'Happy';
        break;
      case 'calm':
      case 'content':
        moodState = 'Calm';
        break;
      case 'tired':
      case 'anxious':
      case 'struggling':
        moodState = 'Anxious';
        break;
      case 'sad':
        moodState = 'Sad';
        break;
      case 'angry':
      case 'needs_support':
        moodState = 'Angry';
        break;
      default:
        moodState = 'Calm';
    }
    return 'assets/images/${gender}_Gif_33FPS/$moodState$gender$number.gif';
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return const Color(0xFFFFD700);
      case 'calm':
      case 'content':
        return const Color(0xFF4ECDC4);
      case 'anxious':
      case 'struggling':
        return const Color(0xFFFFA500);
      case 'sad':
        return const Color(0xFF95A5A6);
      case 'angry':
      case 'needs_support':
        return const Color(0xFFE74C3C);
      default:
        return AppColors.primary;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return '😊';
      case 'calm':
      case 'content':
        return '😌';
      case 'anxious':
      case 'struggling':
        return '😰';
      case 'sad':
        return '😢';
      case 'angry':
      case 'needs_support':
        return '😠';
      default:
        return '😐';
    }
  }

  // Get the most recent mood log entry
  String _getCurrentMoodDisplay() {
    if (_friendMoodLogs.isEmpty) {
      return 'NO MOOD YET';
    }

    // Mood logs are sorted by logged_at descending, so first one is most recent
    final mostRecentLog = _friendMoodLogs.first;
    final mood = mostRecentLog['mood'] ?? 'calm';

    return mood.toUpperCase();
  }

  // Get color for the most recent mood
  Color _getCurrentMoodColor() {
    if (_friendMoodLogs.isEmpty) {
      return Colors.grey;
    }

    final mostRecentLog = _friendMoodLogs.first;
    final mood = mostRecentLog['mood'] ?? 'calm';

    return _getMoodColor(mood);
  }

  // Get time since the mood was logged
  String _getCurrentMoodTimeAgo() {
    if (_friendMoodLogs.isEmpty) {
      return 'No mood logged yet';
    }

    final mostRecentLog = _friendMoodLogs.first;
    final loggedAt = mostRecentLog['logged_at'];

    if (loggedAt == null) return 'Recently';

    try {
      final date = DateTime.parse(loggedAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Logged ${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return 'Logged ${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return 'Logged ${difference.inMinutes}m ago';
      } else {
        return 'Just logged';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _sendEncouragement() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Text('Send Encouragement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a supportive message to ${widget.friendName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'You got this! Keep going! 💪',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a message')),
                );
                return;
              }

              try {
                await _apiService.sendEncouragement(
                  widget.friendId,
                  controller.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Encouragement sent to ${widget.friendName}! 💚'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChallenge() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Challenge Friend'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Challenge ${widget.friendName} to complete a goal!',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 2,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'e.g., Meditate for 10 minutes today',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a challenge')),
                );
                return;
              }

              try {
                await _apiService.sendMessage(
                  widget.friendId,
                  '🏆 Challenge: ${controller.text.trim()}',
                );

                if (mounted) {
                  Navigator.pop(context);
                  // Refresh data immediately to show new challenge
                  await _loadFriendData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Challenge sent to ${widget.friendName}! 🎯'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send Challenge',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FE),
              Color(0xFFE8EAFC),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFriendData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCharacterCard(),
                              const SizedBox(height: 20),
                              _buildStatsCards(),
                              const SizedBox(height: 20),
                              _buildMoodSection(),
                              const SizedBox(height: 20),
                              _buildTodosSection(),
                              const SizedBox(height: 20),
                              _buildChallengesSection(),
                              const SizedBox(height: 20),
                              _buildActionButtons(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.go('/social'),
                tooltip: 'Back',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.friendName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Friend Profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard() {
    final character = _friendProfile?['character'];
    final moodScore = _friendCharacterState?['mood_score']?.toDouble() ?? 50.0;

    // Get current mood from most recent mood log instead of 7-day character state
    final currentMood = _friendMoodLogs.isNotEmpty
        ? (_friendMoodLogs.first['mood'] ?? 'calm')
        : 'calm';

    print('🎭 [CHARACTER DISPLAY] Current mood (most recent): $currentMood');
    print('🎭 [CHARACTER DISPLAY] Mood score (7-day): $moodScore');

    if (character == null) {
      return const SizedBox.shrink();
    }

    // Fix: use 'number' not 'character_number'
    final gender = character['gender'] ?? 'Boy';
    final number = character['number'] ?? 1;

    // Capitalize gender for GIF path
    final genderCapitalized = gender == 'female' ? 'Girl' : 'Boy';
    // Use current mood for GIF display, not character state
    final gifPath =
        _getCharacterGifPath(currentMood, genderCapitalized, number);
    final moodColor = _getMoodColor(currentMood);

    print('🎭 [CHARACTER DISPLAY] GIF path: $gifPath');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColor.withOpacity(0.1),
            moodColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: moodColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character Image (Square)
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: moodColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                gifPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 100,
                    color: moodColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mood Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: moodColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: moodColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMoodEmoji(currentMood),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Mood',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getCurrentMoodDisplay(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCurrentMoodColor(),
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Info text showing when mood was logged
          Text(
            _getCurrentMoodTimeAgo(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Mood Score Bar (7-day average)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mood Score',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A4B80),
                    ),
                  ),
                  Text(
                    '${moodScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: moodColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: moodScore / 100,
                  minHeight: 12,
                  backgroundColor: moodColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final streak = _friendStreak?['current_streak'] ?? 0;
    final xp = _friendProfile?['xp'] ?? 0;
    final level = _friendProfile?['level'] ?? 1;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            title: 'Streak',
            value: '$streak',
            subtitle: 'days',
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            title: 'Level',
            value: '$level',
            subtitle: 'lvl',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            title: 'XP',
            value: '$xp',
            subtitle: 'points',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mood,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '7-Day Mood Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4B80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Track how your friend has been feeling',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          _buildMoodChart(),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    print('📈 [MOOD CHART DEBUG] Mood logs count: ${_friendMoodLogs.length}');
    if (_friendMoodLogs.isNotEmpty) {
      print('📈 [MOOD CHART DEBUG] First mood log: ${_friendMoodLogs.first}');
    }

    if (_friendMoodLogs.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No mood data available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    // Group mood logs by day (last 7 days)
    final now = DateTime.now();
    final last7Days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final moodHeights = <double>[];
    final moodColors = <Color>[];
    final dayLabels = <String>[];

    for (var day in last7Days) {
      dayLabels.add(
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1]);

      // Find mood log for this day
      final dayLog = _friendMoodLogs.firstWhere(
        (log) {
          final logDate = DateTime.parse(log['logged_at']);
          return logDate.year == day.year &&
              logDate.month == day.month &&
              logDate.day == day.day;
        },
        orElse: () => null,
      );

      if (dayLog != null) {
        final mood = dayLog['mood'] as String;
        final moodScores = {
          'happy': 100.0,
          'calm': 80.0,
          'tired': 50.0,
          'anxious': 30.0,
          'sad': 20.0,
          'angry': 10.0,
        };
        final moodColorMap = {
          'happy': const Color(0xFFFFD700),
          'calm': const Color(0xFF4ECDC4),
          'tired': const Color(0xFF95A5A6),
          'anxious': const Color(0xFFFFA500),
          'sad': const Color(0xFF9575CD),
          'angry': const Color(0xFFE74C3C),
        };
        moodHeights.add(moodScores[mood] ?? 50.0);
        moodColors.add(moodColorMap[mood] ?? Colors.grey);
      } else {
        moodHeights.add(0.0);
        moodColors.add(Colors.grey[300]!);
      }
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final height = moodHeights[index];
          final hasData = height > 0;

          return Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasData)
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: moodColors[index],
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: hasData ? (height * 0.5) : 10,
                  decoration: BoxDecoration(
                    color: moodColors[index],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 9,
                    color: hasData ? Colors.black87 : Colors.grey,
                    fontWeight: hasData ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTodosSection() {
    final completedCount =
        _friendTodos.where((t) => t['is_completed'] == true).length;
    final totalCount = _friendTodos.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.checklist,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.friendName}\'s Goals Today',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4B80),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_friendTodos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No goals set for today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Fixed height container showing ~3 items with scrolling
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220, // ~3 items (each ~70px)
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _friendTodos.length,
                itemBuilder: (context, index) {
                  return _buildTodoItem(_friendTodos[index]);
                },
              ),
            ),
          if (_friendTodos.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Scroll for ${_friendTodos.length - 3} more goals',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final isCompleted = todo['is_completed'] ?? false;
    // Backend returns 'task_text' not 'title'
    final title = todo['task_text'] ?? todo['title'] ?? 'Untitled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCompleted ? AppColors.success.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.grey : const Color(0xFF0A4B80),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    return Column(
      children: [
        _buildChallengesSentSection(),
        const SizedBox(height: 16),
        _buildChallengesReceivedSection(),
      ],
    );
  }

  Widget _buildChallengesSentSection() {
    // Filter messages I sent to this friend (challenges I set)
    print('🔍 [CHALLENGES SENT DEBUG] Current user ID: $_currentUserId');
    print('🔍 [CHALLENGES SENT DEBUG] Friend ID: ${widget.friendId}');
    print(
        '🔍 [CHALLENGES SENT DEBUG] Total messages: ${_friendMessages.length}');

    // Filter messages where I am the sender AND friend is the receiver
    final myChallenges = _friendMessages
        .where((msg) =>
            msg['sender_id'] == _currentUserId &&
            msg['receiver_id'] == widget.friendId)
        .toList();

    print(
        '🎯 [CHALLENGES SENT DEBUG] My challenges to friend ${widget.friendId}: ${myChallenges.length}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Challenges Sent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4B80),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${myChallenges.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (myChallenges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'You haven\'t sent any challenges yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Fixed height container showing ~3 items with scrolling
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 270, // ~3 items (each ~85-90px with spacing)
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: myChallenges.length,
                itemBuilder: (context, index) {
                  return _buildChallengeItem(myChallenges[index]);
                },
              ),
            ),
          if (myChallenges.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Scroll for ${myChallenges.length - 3} more challenges',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengesReceivedSection() {
    // Filter messages friend sent to me (challenges I received)
    print('🔍 [CHALLENGES RECEIVED DEBUG] Current user ID: $_currentUserId');
    print('🔍 [CHALLENGES RECEIVED DEBUG] Friend ID: ${widget.friendId}');

    // Filter messages where friend is the sender AND I am the receiver
    final receivedChallenges = _friendMessages
        .where((msg) =>
            msg['sender_id'] == widget.friendId &&
            msg['receiver_id'] == _currentUserId)
        .toList();

    print(
        '🎯 [CHALLENGES RECEIVED DEBUG] Challenges from friend ${widget.friendId}: ${receivedChallenges.length}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Challenges Received',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4B80),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${receivedChallenges.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (receivedChallenges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No challenges received yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Fixed height container showing ~3 items with scrolling
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 270, // ~3 items (each ~85-90px with spacing)
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: receivedChallenges.length,
                itemBuilder: (context, index) {
                  return _buildReceivedChallengeItem(receivedChallenges[index]);
                },
              ),
            ),
          if (receivedChallenges.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Scroll for ${receivedChallenges.length - 3} more challenges',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(Map<String, dynamic> challenge) {
    final isRead = challenge['is_read'] ?? false;
    final message = challenge['message'] ?? '';
    final createdAt = challenge['created_at'] ?? '';

    // Parse date
    String timeAgo = 'Recently';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    } catch (e) {
      // Keep default timeAgo
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isRead ? Colors.grey[200]! : AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRead ? Icons.check_circle_outline : Icons.pending_outlined,
            color: isRead ? AppColors.success : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A4B80),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedChallengeItem(Map<String, dynamic> challenge) {
    final isCompleted = challenge['is_completed'] ?? false;
    final message = challenge['message'] ?? '';
    final createdAt = challenge['created_at'] ?? '';
    final messageId = challenge['id'];

    // Parse date
    String timeAgo = 'Recently';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    } catch (e) {
      // Keep default timeAgo
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCompleted ? AppColors.success.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleChallengeCompletion(messageId, !isCompleted),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? AppColors.success : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.grey : const Color(0xFF0A4B80),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleChallengeCompletion(
      int messageId, bool isCompleted) async {
    try {
      // Update challenge completion status via API
      await _apiService.updateMessageCompletion(messageId, isCompleted);

      // Reload data to reflect changes
      await _loadFriendData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Challenge marked as completed! 🎉'
                  : 'Challenge marked as incomplete',
            ),
            backgroundColor: isCompleted ? AppColors.success : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update challenge status'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Send Encouragement Button
        InkWell(
          onTap: _sendEncouragement,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF28A745)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Send Encouragement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Send Challenge Button
        InkWell(
          onTap: _sendChallenge,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Send Challenge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
