import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'friend_profile/tabs/challenges_tab.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/utils/image_cache_manager.dart';
import '../../../core/widgets/keep_alive_wrapper.dart';
import '../../../core/utils/debouncer.dart';

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

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _friendProfile;
  Map<String, dynamic>? _friendCharacterState;
  List<dynamic> _friendTodos = [];
  List<dynamic> _friendMoodLogs = [];
  List<dynamic> _friendMessages = [];
  int? _currentUserId;

  // Tab Controller
  late TabController _tabController;
  final Debouncer _actionDebouncer =
      Debouncer(duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fast load: show cached immediately, then background refresh
    _loadCachedFirst();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Display cached data instantly without blocking, then refresh in background
  void _loadCachedFirst() {
    final cacheKey = 'friend_profile_${widget.friendId}';

    // Non-blocking cache read for instant display
    CacheService()
        .get<Map<String, dynamic>>(
      cacheKey,
      maxAge: const Duration(minutes: 5),
    )
        .then((cachedData) {
      if (cachedData != null && mounted) {
        setState(() {
          _currentUserId = cachedData['currentUserId'];
          _friendProfile = cachedData['profile'];
          _friendCharacterState = cachedData['characterState'];
          
          // Filter cached todos too (Today Only, No Quests)
          final cachedTodos = cachedData['todos'] ?? [];
          final now = DateTime.now();
          _friendTodos = (cachedTodos as List).where((t) {
             // Exclude Quests
             final isQuest = (t['is_quest'] == true) || (t['category'] != null) || (t['difficulty'] != null);
             if (isQuest) return false;
             if (t['task_text'] == null) return false;

             // Date Filter
             final created = DateTime.parse(t['created_at']).toLocal();
             return created.year == now.year && created.month == now.month && created.day == now.day;
          }).toList();
          
          _friendMoodLogs = cachedData['moodLogs'] ?? [];
          _friendMessages = cachedData['messages'] ?? [];
          _isLoading = false;
        });
      }
    });

    // Background refresh
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    try {
      final cacheKey = 'friend_profile_${widget.friendId}';

      // Get current user ID
      final currentUser = await _apiService.getCurrentUser();
      final currentUserId = currentUser['id'];

      // Fetch all data in parallel for speed
      final results = await Future.wait([
        _apiService.getFriendProfile(widget.friendId, forceRefresh: true),
        _apiService.getFriendCharacterMoodState(widget.friendId,
            forceRefresh: true),
        _apiService.getFriendMoodLogs(widget.friendId),
        _apiService.getFriendTodos(widget.friendId), // Fetch ALL, we filter manually
        _apiService.getMessages(widget.friendId),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final characterState = results[1] as Map<String, dynamic>;
      final moodLogs = results[2] as List<dynamic>;
      var todos = results[3] as List<dynamic>;
      final messages = results[4] as List<dynamic>;

      // FILTER: Only show Manual Todos created TODAY. Exclude Quests.
      final now = DateTime.now();
      todos = todos.where((t) {
        // Exclude Quests
        final isQuest = (t['is_quest'] == true) || (t['category'] != null) || (t['difficulty'] != null);
        if (isQuest) return false;
        if (t['task_text'] == null) return false;
        
        // Date Filter
        final created = DateTime.parse(t['created_at']).toLocal();
        return created.year == now.year && created.month == now.month && created.day == now.day;
      }).toList();

      // Update cache
      await CacheService().set(cacheKey, {
        'currentUserId': currentUserId,
        'profile': profile,
        'characterState': characterState,
        'todos': todos,
        'moodLogs': moodLogs,
        'messages': messages,
      });

      // Update UI with fresh data
      if (mounted) {
        setState(() {
          _currentUserId = currentUserId;
          _friendProfile = profile;
          _friendCharacterState = characterState;
          _friendMoodLogs = moodLogs;
          _friendTodos = todos;
          _friendMessages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading friend data: $e');
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
        moodState = 'Tired'; // ✅ Fixed: Tired gets its own GIF
        break;
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
      case 'tired':
        return const Color(0xFF95A5A6); // Gray for tired
      case 'anxious':
      case 'struggling':
        return const Color(0xFFFFA500);
      case 'sad':
        return const Color(0xFF9575CD); // Purple for sad
      case 'angry':
      case 'needs_support':
        return const Color(0xFFE74C3C);
      default:
        return AppColors.primary;
    }
  }

  // Removed _getMoodEmoji for minimalistic design

  // Get the most recent mood log entry
  String _getCurrentMoodDisplay() {
    if (_friendMoodLogs.isEmpty) {
      return 'NO MOOD YET';
    }

    // ✅ FIX: Sort mood logs to get the most recent one
    final sortedLogs = List<dynamic>.from(_friendMoodLogs)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['logged_at'] ?? '');
        final dateB = DateTime.parse(b['logged_at'] ?? '');
        return dateB.compareTo(dateA); // Newest first
      });

    final mostRecentLog = sortedLogs.first;
    final mood = mostRecentLog['mood'] ?? 'calm';

    return mood.toUpperCase();
  }

  // Get color for the most recent mood
  Color _getCurrentMoodColor() {
    if (_friendMoodLogs.isEmpty) {
      return Colors.grey;
    }

    // ✅ FIX: Sort mood logs to get the most recent one
    final sortedLogs = List<dynamic>.from(_friendMoodLogs)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['logged_at'] ?? '');
        final dateB = DateTime.parse(b['logged_at'] ?? '');
        return dateB.compareTo(dateA); // Newest first
      });

    final mostRecentLog = sortedLogs.first;
    final mood = mostRecentLog['mood'] ?? 'calm';

    return _getMoodColor(mood);
  }

  // Get time since the mood was logged
  String _getCurrentMoodTimeAgo() {
    if (_friendMoodLogs.isEmpty) {
      return 'No mood logged yet';
    }

    // ✅ FIX: Sort mood logs to get the most recent one
    final sortedLogs = List<dynamic>.from(_friendMoodLogs)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['logged_at'] ?? '');
        final dateB = DateTime.parse(b['logged_at'] ?? '');
        return dateB.compareTo(dateA); // Newest first
      });

    final mostRecentLog = sortedLogs.first;
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

  Widget _buildFriendProfileSkeleton() {
    return SafeArea(
      child: Column(
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SkeletonLoader.character(size: 40),
                const SizedBox(width: 12),
                Expanded(child: SkeletonLoader.text(width: 150, height: 24)),
              ],
            ),
          ),
          // Content skeleton
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Character card skeleton
                    SkeletonLoader.card(height: 350),
                    const SizedBox(height: 20),
                    // Stats cards skeleton
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.card(height: 90)),
                        const SizedBox(width: 12),
                        Expanded(child: SkeletonLoader.card(height: 90)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.card(height: 90)),
                        const SizedBox(width: 12),
                        Expanded(child: SkeletonLoader.card(height: 90)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action buttons skeleton
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.card(height: 80)),
                        const SizedBox(width: 12),
                        Expanded(child: SkeletonLoader.card(height: 80)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Tab content skeleton
                    SkeletonLoader.card(height: 200),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEncouragement() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.favorite,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Send Encouragement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Icon(Icons.close, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Send a supportive message to ${widget.friendName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 200,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'You got this! Keep going!',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter a message')),
                              );
                              return;
                            }

                            final message = controller.text.trim();
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Encouragement sent to ${widget.friendName}'),
                                backgroundColor: AppColors.success,
                              ),
                            );

                            _actionDebouncer.run(() async {
                              try {
                                await _apiService.sendEncouragement(
                                  widget.friendId,
                                  message,
                                );
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
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Send',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendChallenge() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.emoji_events, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Challenge Friend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Icon(Icons.close, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Challenge ${widget.friendName} to complete a goal!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    maxLength: 100,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g., Meditate for 10 minutes today',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFFF9500), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a challenge')),
                            );
                            return;
                          }

                          final challengeText = controller.text.trim();
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Challenge sent to ${widget.friendName}'),
                              backgroundColor: AppColors.warning,
                            ),
                          );

                          _actionDebouncer.run(() async {
                            try {
                              await _apiService.sendMessage(
                                widget.friendId,
                                'Challenge: $challengeText',
                              );

                              final newMessages = await _apiService
                                  .getMessages(widget.friendId);
                              if (mounted) {
                                setState(() {
                                  _friendMessages = newMessages;
                                });
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
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Send Challenge',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
            ? _buildFriendProfileSkeleton()
            : SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Scrollable Content with Character, Stats, Tabs
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFriendData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Character Card & Stats
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                child: Column(
                                  children: [
                                    _buildCharacterCard(),
                                    const SizedBox(height: 20),
                                    _buildStatsCards(),
                                  ],
                                ),
                              ),

                              // Tab Bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicator: BoxDecoration(
                                      color: const Color(0xFF6C5CE7),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor:
                                        const Color(0xFF6B8BA8),
                                    labelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicatorPadding: const EdgeInsets.all(4),
                                    dividerColor: Colors.transparent,
                                    tabs: const [
                                      Tab(text: 'Tasks'),
                                      Tab(text: 'Challenges'),
                                    ],
                                  ),
                                ),
                              ),

                              // Action Buttons (outside tabs)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                child: _buildActionButtons(),
                              ),

                              // Tab Content (increased height to fit content)
                              SizedBox(
                                height:
                                    750, // Increased height to prevent overflow
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    // Goals Tab
                                    KeepAliveWrapper(child: _buildGoalsTab()),

                                    // Challenges Tab
                                    KeepAliveWrapper(
                                      child: ChallengesTab(
                                        friendMessages: _friendMessages,
                                        currentUserId: _currentUserId ?? 0,
                                        friendId: widget.friendId,
                                        onToggleCompletion:
                                            _toggleChallengeCompletion,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20), // Bottom padding
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
                onPressed: () => context.pop(),
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

    // ✅ FIX: Sort mood logs by timestamp (most recent first)
    final sortedMoodLogs = List<dynamic>.from(_friendMoodLogs)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['logged_at'] ?? '');
        final dateB = DateTime.parse(b['logged_at'] ?? '');
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

    // ✅ CHANGE: Use most recent mood log
    // If no logs, currentMood is null (neutral state)
    final currentMood = sortedMoodLogs.isNotEmpty
        ? (sortedMoodLogs.first['mood'] ?? 'calm')
        : null;

    // ✅ HANDLE NULL: Show placeholder if friend hasn't chosen character
    if (character == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.person_outline, size: 120, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '${widget.friendName} hasn\'t chosen a character yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Fix: use 'number' not 'character_number'
    final gender = character['gender'] ?? 'male';
    final number = character['number'] ?? 1;

    // Capitalize gender for GIF path (backend returns 'male'/'female')
    final genderCapitalized = (gender as String).toLowerCase() == 'girl' ? 'Girl' : 'Boy';
    // Use current mood for GIF display, not character state
    final gifPath =
        _getCharacterGifPath(currentMood ?? 'calm', genderCapitalized, number);
        
    // Use Grey/Neutral color if mood is null
    final moodColor = currentMood != null ? _getMoodColor(currentMood) : Colors.grey;

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
              child: ImageCacheManager().buildCachedImage(
                assetPath: gifPath,
                fit: BoxFit.cover,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Current Mood',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentMood != null ? _getCurrentMoodDisplay() : '---',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentMood != null ? _getCurrentMoodColor() : Colors.grey,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
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
    final streak = _friendProfile?['current_streak'] ?? 0;
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
          colors: [color.withOpacity(0.85), color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
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

  Widget _buildGoalsTab() {
    final completedCount =
        _friendTodos.where((t) => t['is_completed'] == true).length;
    final totalCount = _friendTodos.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User's Goal for the Day (Takes remaining space, scrollable internally)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.15),
                    const Color(0xFF764BA2).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.friendName}\'s Tasks Today',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A4B80),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Progress: $completedCount/$totalCount completed',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_friendTodos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'No tasks set for today',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    // Scrollable area for goals (takes remaining space)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _friendTodos.length,
                        itemBuilder: (context, index) {
                          // Sort todos: uncompleted first, then by created_at descending
                          final sortedTodos = List<dynamic>.from(_friendTodos);
                          sortedTodos.sort((a, b) {
                            final aCompleted = a['is_completed'] ?? false;
                            final bCompleted = b['is_completed'] ?? false;

                            if (aCompleted != bCompleted) {
                              return aCompleted ? 1 : -1; // Uncompleted first
                            }

                            // Same completion status, sort by ID (newest first)
                            return (b['id'] as int).compareTo(a['id'] as int);
                          });

                          return _buildTodoItemLarge(sortedTodos[index]);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItemLarge(Map<String, dynamic> todo) {
    final isCompleted = todo['is_completed'] ?? false;
    final title = todo['task_text'] ?? todo['title'] ?? 'Untitled';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.4)
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? AppColors.success.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : Colors.grey[400],
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCompleted ? Colors.grey[600] : const Color(0xFF0A4B80),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleChallengeCompletion(
      int messageId, bool isCompleted) async {
    // 1. Optimistic Update
    setState(() {
      final index = _friendMessages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        _friendMessages[index]['is_completed'] = isCompleted;
      }
    });

    // Show feedback immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? 'Challenge marked as completed'
                : 'Challenge marked as incomplete',
          ),
          backgroundColor: isCompleted ? AppColors.success : Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // 2. API Call in background
      await _apiService.updateMessageCompletion(messageId, isCompleted);
    } catch (e) {
      // 3. Revert on failure
      setState(() {
        final index = _friendMessages.indexWhere((m) => m['id'] == messageId);
        if (index != -1) {
          _friendMessages[index]['is_completed'] = !isCompleted;
        }
      });

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
    return Row(
      children: [
        // Send Encouragement Button
        Expanded(
          child: InkWell(
            onTap: _sendEncouragement,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    'Encouragement',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Send Challenge Button
        Expanded(
          child: InkWell(
            onTap: _sendChallenge,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9500).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    'Challenge',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
