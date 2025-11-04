import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _friendRequests = [];
  List<dynamic> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when dependencies change (e.g., after login/logout)
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _apiService.getFriends();
      final requests = await _apiService.getReceivedFriendRequests();
      final sent = await _apiService.getSentFriendRequests();

      if (mounted) {
        setState(() {
          _friends = friends;
          _friendRequests = requests;
          _sentRequests = sent;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading social data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FE),
              const Color(0xFFE8EAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and add friend button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => context.go('/home'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Friends',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.person_add_rounded,
                          color: AppColors.primary),
                      onPressed: _showAddFriendDialog,
                      iconSize: 28,
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Friends'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Requests'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Sent'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tab Views
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFriendsTab(),
                          _buildRequestsTab(),
                          _buildSentTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No friends yet',
        subtitle: 'Tap + to add friends and share your journey!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        title: 'No friend requests',
        subtitle: 'When someone sends you a request, it will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No sent requests',
        subtitle: 'Friend requests you send will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          return _buildSentRequestCard(request);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to fetch friend mood data - creates a new Future each time
  Future<List<Map<String, dynamic>>> _fetchFriendMoodData(int friendId) async {
    return Future.wait([
      _apiService.getFriendProfile(friendId),
      _apiService
          .getFriendCharacterMoodState(friendId)
          .catchError((_) => <String, dynamic>{}),
    ]);
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final String friendName =
        '${friend['friend_first_name'] ?? ''} ${friend['friend_last_name'] ?? ''}'
            .trim();
    final int friendId = friend['friend_id'];

    return GestureDetector(
      onTap: () => _showAccountabilityView(friend),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Character mood GIF (square) - using unique key per friend
            FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('friend_mood_${friendId}_${_friends.length}'),
              future: _fetchFriendMoodData(friendId),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data![0]['character'] != null) {
                  final character = snapshot.data![0]['character'];
                  final moodStateData = snapshot.data![1];
                  final gender = character['gender'] ?? 'boy';
                  final characterNumber = character['number'] ?? 1;

                  print('[DEBUG UI] Friend card for friendId: $friendId');
                  print(
                      '[DEBUG UI] Character: gender=$gender, number=$characterNumber');
                  print('[DEBUG UI] Mood state data: $moodStateData');

                  // Map character_state to mood state for GIF filename (proper case)
                  String moodState = 'Calm'; // Default to Calm
                  if (moodStateData.isNotEmpty &&
                      moodStateData['character_state'] != null) {
                    print(
                        '[DEBUG UI] Character state: ${moodStateData['character_state']}');
                    switch (moodStateData['character_state']) {
                      case 'thriving':
                        moodState = 'Happy';
                        break;
                      case 'content':
                        moodState = 'Calm';
                        break;
                      case 'struggling':
                        moodState = 'Sad';
                        break;
                      case 'needs_support':
                        moodState = 'Angry';
                        break;
                      default:
                        moodState = 'Calm';
                    }
                  }
                  print('[DEBUG UI] Final mood state for GIF: $moodState');

                  final genderPrefix = gender == 'female' ? 'Girl' : 'Boy';

                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/${genderPrefix}_Gif_33FPS/$moodState$genderPrefix$characterNumber.gif',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to Calm if mood-specific GIF doesn't exist
                          return Image.asset(
                            'assets/images/${genderPrefix}_Gif_33FPS/Calm$genderPrefix$characterNumber.gif',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person,
                                  size: 32, color: AppColors.textSecondary);
                            },
                          );
                        },
                      ),
                    ),
                  );
                }
                // Fallback to gradient with initial
                final String firstLetter =
                    friendName.isNotEmpty ? friendName[0].toUpperCase() : '?';
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFriendMoodData(friendId),
                builder: (context, snapshot) {
                  String? currentMood;
                  Color moodColor = AppColors.primary;

                  if (snapshot.hasData && snapshot.data!.length > 1) {
                    final moodStateData = snapshot.data![1];
                    if (moodStateData.isNotEmpty &&
                        moodStateData['character_state'] != null) {
                      // Map character_state to mood label
                      switch (moodStateData['character_state']) {
                        case 'thriving':
                          currentMood = 'Happy';
                          moodColor = const Color(0xFFFFD54F);
                          break;
                        case 'content':
                          currentMood = 'Calm';
                          moodColor = const Color(0xFF42A5F5);
                          break;
                        case 'struggling':
                          currentMood = 'Sad';
                          moodColor = const Color(0xFF9575CD);
                          break;
                        case 'needs_support':
                          currentMood = 'Needs Support';
                          moodColor = const Color(0xFFEF5350);
                          break;
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName.isEmpty ? 'Unknown' : friendName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 16, color: AppColors.gameYellow),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${friend['friend_level'] ?? 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (currentMood != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.mood_rounded,
                              size: 16,
                              color: moodColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentMood,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: moodColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.primary),
              onPressed: () => _showFriendOptions(friend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final String senderName =
        '${request['sender_first_name'] ?? ''} ${request['sender_last_name'] ?? ''}'
            .trim();
    final String firstLetter =
        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName.isEmpty ? 'Unknown' : senderName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wants to connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.stateThriving.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      Icon(Icons.check_rounded, color: AppColors.stateThriving),
                  onPressed: () => _acceptFriendRequest(request['id']),
                  iconSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.error),
                  onPressed: () => _rejectFriendRequest(request['id']),
                  iconSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestCard(Map<String, dynamic> request) {
    final String receiverName =
        '${request['sender_first_name'] ?? ''} ${request['sender_last_name'] ?? ''}'
            .trim();
    final String firstLetter =
        receiverName.isNotEmpty ? receiverName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gameBlue, AppColors.gamePurple],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName.isEmpty ? 'Unknown' : receiverName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _cancelFriendRequest(request['id']),
            icon: Icon(Icons.close_rounded, size: 18, color: AppColors.error),
            label: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Add Friend',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter friend\'s email',
                prefixIcon: Icon(Icons.email_rounded, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendFriendRequest(searchController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Request',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountabilityView(Map<String, dynamic> friend) {
    final String friendName =
        '${friend['friend_first_name'] ?? ''} ${friend['friend_last_name'] ?? ''}'
            .trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    // Friend's character GIF with mood state (square)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      key: ValueKey(
                          'accountability_mood_${friend['friend_id']}_${DateTime.now().millisecondsSinceEpoch}'),
                      future: _fetchFriendMoodData(friend['friend_id']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data![0]['character'] != null) {
                          final character = snapshot.data![0]['character'];
                          final moodStateData = snapshot.data![1];
                          final gender = character['gender'] ?? 'boy';
                          final characterNumber = character['number'] ?? 1;

                          // Map character_state to mood state for GIF filename
                          String moodState = 'neutral';
                          if (moodStateData.isNotEmpty &&
                              moodStateData['character_state'] != null) {
                            switch (moodStateData['character_state']) {
                              case 'thriving':
                                moodState = 'Happy';
                                break;
                              case 'content':
                                moodState = 'Calm';
                                break;
                              case 'struggling':
                                moodState = 'Sad';
                                break;
                              case 'needs_support':
                                moodState = 'Angry';
                                break;
                              default:
                                moodState = 'Calm';
                            }
                          }

                          final genderPrefix =
                              gender == 'female' ? 'Girl' : 'Boy';

                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Image.asset(
                                'assets/images/${genderPrefix}_Gif_33FPS/$moodState$genderPrefix$characterNumber.gif',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to Calm if mood-specific GIF doesn't exist
                                  return Image.asset(
                                    'assets/images/${genderPrefix}_Gif_33FPS/Calm$genderPrefix$characterNumber.gif',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person,
                                          size: 40,
                                          color: AppColors.textSecondary);
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        // Fallback to gradient square with initial
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              friendName.isNotEmpty
                                  ? friendName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friendName.isEmpty ? 'Unknown' : friendName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Accountability Partner',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tabs for different accountability features
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Tasks'),
                            Tab(text: 'Streaks'),
                            Tab(text: 'Challenges'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTaskAccountabilityTab(
                                friend, scrollController),
                            _buildStreakComparisonTab(friend, scrollController),
                            _buildChallengesTab(friend, scrollController),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Task Accountability Tab - Share and see each other's daily tasks
  Widget _buildTaskAccountabilityTab(
      Map<String, dynamic> friend, ScrollController scrollController) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _loadAccountabilityTasks(friend),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final myTasks = snapshot.data?['myTasks'] ?? [];
        final friendTasks = snapshot.data?['friendTasks'] ?? [];

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            _buildInfoCard(
              icon: Icons.task_alt,
              title: 'Task Accountability',
              description:
                  'Share your daily tasks and keep each other motivated!',
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),

            // Your Tasks Today
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Tasks Today',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (myTasks.isEmpty)
              _buildEmptyTaskState('No tasks for today', Icons.inbox_outlined)
            else
              ...myTasks.map((task) => _buildTaskCard(
                    task['task_text'] ?? 'Untitled Task',
                    task['is_completed'] ?? false,
                    task['is_completed'] == true
                        ? AppColors.success
                        : AppColors.warning,
                  )),

            const SizedBox(height: 32),

            // Friend's Shared Tasks
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (friend['friend_first_name'] != null &&
                              friend['friend_first_name'].toString().isNotEmpty)
                          ? friend['friend_first_name']
                              .toString()[0]
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${friend['friend_first_name'] ?? 'Friend'}'s Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (friendTasks.isEmpty)
              _buildEmptyTaskState(
                  'No shared tasks yet', Icons.visibility_off_outlined)
            else
              ...friendTasks.map((task) => _buildTaskCard(
                    task['task_text'] ?? 'Untitled Task',
                    task['is_completed'] ?? false,
                    task['is_completed'] == true
                        ? AppColors.success
                        : AppColors.warning,
                  )),

            const SizedBox(height: 32),

            // Send Encouragement Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _sendEncouragement(friend),
                icon: const Icon(Icons.favorite_rounded, size: 22),
                label: const Text(
                  'Send Encouragement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Future<Map<String, List<dynamic>>> _loadAccountabilityTasks(
      Map<String, dynamic> friend) async {
    try {
      // Fetch your tasks for today
      final myTasks = await _apiService.getTodos(
        periodType: 'daily',
        limit: 50,
      );

      // Filter to only today's tasks
      final today = DateTime.now();
      final myTodayTasks = myTasks.where((task) {
        final createdAt = DateTime.parse(task['created_at']).toLocal();
        return createdAt.year == today.year &&
            createdAt.month == today.month &&
            createdAt.day == today.day;
      }).toList();

      // Fetch friend's tasks
      List<dynamic> friendTasks = [];
      try {
        final friendUserId =
            friend['friend_id']; // This is the actual user_id of the friend
        if (friendUserId != null) {
          final allFriendTasks = await _apiService.getFriendTodos(
            friendUserId,
            periodType: 'daily',
          );

          // Filter to today's tasks
          friendTasks = allFriendTasks.where((task) {
            final createdAt = DateTime.parse(task['created_at']).toLocal();
            return createdAt.year == today.year &&
                createdAt.month == today.month &&
                createdAt.day == today.day;
          }).toList();
        }
      } catch (e) {
        print('Error loading friend tasks: $e');
        // If API endpoint doesn't exist yet, friendTasks stays empty
      }

      return {
        'myTasks': myTodayTasks,
        'friendTasks': friendTasks,
      };
    } catch (e) {
      print('Error loading accountability tasks: $e');
      return {
        'myTasks': [],
        'friendTasks': [],
      };
    }
  }

  Widget _buildEmptyTaskState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Streak Comparison Tab - Compare streaks and celebrate together
  Widget _buildStreakComparisonTab(
      Map<String, dynamic> friend, ScrollController scrollController) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStreakData(friend),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final myStreak = snapshot.data?['myStreak'] ?? {};
        final friendStreak = snapshot.data?['friendStreak'] ?? {};
        final hasData = myStreak.isNotEmpty || friendStreak.isNotEmpty;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            _buildInfoCard(
              icon: Icons.local_fire_department_rounded,
              title: 'Streak Challenge',
              description: 'Compare your consistency and motivate each other!',
              color: AppColors.warning,
            ),
            const SizedBox(height: 32),

            // Your Streaks
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Current Streaks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (myStreak.isEmpty)
              _buildEmptyTaskState(
                'Start logging your activities to build streaks!',
                Icons.timeline_outlined,
              )
            else
              _buildStreakCard(
                title: '',
                items: [
                  {
                    'label': 'Current Streak',
                    'days': myStreak['current_streak'] ?? 0,
                    'color': AppColors.info
                  },
                  {
                    'label': 'Longest Streak',
                    'days': myStreak['longest_streak'] ?? 0,
                    'color': AppColors.success
                  },
                ],
              ),

            const SizedBox(height: 32),

            // Friend's Streaks
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (friend['friend_first_name'] != null &&
                              friend['friend_first_name'].toString().isNotEmpty)
                          ? friend['friend_first_name']
                              .toString()[0]
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${friend['friend_first_name'] ?? 'Friend'}'s Streaks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (friendStreak.isEmpty)
              _buildEmptyTaskState(
                'No streak data available yet',
                Icons.visibility_off_outlined,
              )
            else
              _buildStreakCard(
                title: '',
                items: [
                  {
                    'label': 'Current Streak',
                    'days': friendStreak['current_streak'] ?? 0,
                    'color': AppColors.info
                  },
                  {
                    'label': 'Longest Streak',
                    'days': friendStreak['longest_streak'] ?? 0,
                    'color': AppColors.success
                  },
                ],
              ),

            const SizedBox(height: 32),

            // Combined Streak Goal (if both have data)
            if (hasData)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gameYellow.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gameYellow.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gameYellow.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gameYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 48,
                        color: AppColors.gameYellow,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keep Each Other Motivated! 🔥',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consistency is key to mental wellness',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStreakData(
      Map<String, dynamic> friend) async {
    try {
      // Fetch your streak
      final myStreak = await _apiService.getMyStreak();

      // Fetch friend's streak
      Map<String, dynamic> friendStreak = {};
      try {
        final friendUserId =
            friend['friend_id']; // This is the actual user_id of the friend
        if (friendUserId != null) {
          friendStreak = await _apiService.getFriendStreak(friendUserId);
        }
      } catch (e) {
        print('Error loading friend streak: $e');
        // If API endpoint doesn't exist yet, friendStreak stays empty
      }

      return {
        'myStreak': myStreak,
        'friendStreak': friendStreak,
      };
    } catch (e) {
      print('Error loading streak data: $e');
      return {
        'myStreak': {},
        'friendStreak': {},
      };
    }
  }

  // Challenges Tab - Create and participate in challenges
  Widget _buildChallengesTab(
      Map<String, dynamic> friend, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        _buildInfoCard(
          icon: Icons.emoji_events_rounded,
          title: 'Accountability Challenges',
          description: 'Create challenges and compete together!',
          color: AppColors.secondary,
        ),
        const SizedBox(height: 32),

        // Active Challenges
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildChallengeCard(
          title: '7-Day Mood Logging',
          description: 'Log mood every day for 7 days',
          progress: 0.6,
          daysLeft: 3,
          color: AppColors.info,
        ),

        _buildChallengeCard(
          title: 'Journal Every Night',
          description: 'Write a journal entry before bed',
          progress: 0.4,
          daysLeft: 5,
          color: AppColors.success,
        ),

        const SizedBox(height: 32),

        // Create New Challenge Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateChallengeDialog(friend),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Create New Challenge',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, bool isCompleted, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? color.withValues(alpha: 0.3) : Colors.grey[200]!,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? color.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 16 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item['color'].withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item['color'].withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['color'].withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: item['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item['color'],
                            item['color'].withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: item['color'].withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${item['days']} days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required double progress,
    required int daysLeft,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$daysLeft',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'days',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Progress Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'On Track',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateChallengeDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Challenge Name',
                hintText: 'e.g., 30-Day Meditation',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Duration (days)',
                hintText: '7',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Challenge created! 🎯')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              title: Text(
                'View Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _viewFriendProfile(friend);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
              ),
              title: Text(
                'Send Message',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendMessage(friend);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.person_remove_rounded, color: AppColors.error),
              ),
              title: Text(
                'Remove Friend',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFriend(friend['friend_id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String query) async {
    try {
      await _apiService.sendFriendRequest(query);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error sending friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _acceptFriendRequest(int requestId) async {
    try {
      await _apiService.acceptFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _rejectFriendRequest(int requestId) async {
    try {
      await _apiService.rejectFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _cancelFriendRequest(int requestId) async {
    try {
      await _apiService.cancelFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error cancelling friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _removeFriend(int friendId) async {
    try {
      await _apiService.removeFriend(friendId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error removing friend: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _sendEncouragement(Map<String, dynamic> friend) async {
    try {
      final friendId = friend['friend_id'];
      await _apiService.sendEncouragement(
        friendId,
        'Keep up the great work! 💪',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Encouragement sent! 💪'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sending encouragement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send encouragement: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _viewFriendProfile(Map<String, dynamic> friend) async {
    try {
      final friendUserId = friend['friend_user_id'] ?? friend['user_id'];
      if (friendUserId == null) return;

      final profile = await _apiService.getFriendProfile(friendUserId);

      if (!mounted) return;

      // Show profile dialog with character
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${profile['first_name']} ${profile['last_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Character image/gif
              if (profile['character'] != null) ...[
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      profile['character']['name'] ?? 'Character',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                profile['email'] ?? '',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              if (profile['interests'] != null &&
                  profile['interests'].isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Interests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (profile['interests'] as List).map((interest) {
                    return Chip(
                      label: Text(interest['name'] ?? ''),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error viewing friend profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(Map<String, dynamic> friend) async {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message ${friend['friend_first_name']}'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;

              try {
                final friendId = friend['friend_id'];
                await _apiService.sendMessage(
                  friendId,
                  messageController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Message sent! 💬'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                print('Error sending message: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to send message'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
