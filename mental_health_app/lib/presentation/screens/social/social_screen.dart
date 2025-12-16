import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/utils/image_cache_manager.dart';
import '../../../core/widgets/keep_alive_wrapper.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/providers/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _apiService = ApiService();
  late TabController _tabController;
  final Debouncer _actionDebouncer = Debouncer(milliseconds: 350);

  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _friendRequests = [];
  List<dynamic> _sentRequests = [];

  // Cache for friend mood data to avoid repeated API calls
  Map<int, Map<String, dynamic>> _friendMoodCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  // ✅ FIX: Refresh when app comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _friends.isNotEmpty) {
      _refreshMoodCache(friendsList: _friends);
    }
  }

  /// Refresh friend mood data in background without showing loading spinner.
  /// Processes friends in chunks to avoid overwhelming the server.
  Future<void> _refreshMoodCache(
      {List<dynamic>? friendsList, bool forceRefresh = false}) async {
    final listToUse = friendsList ?? _friends;
    if (listToUse.isEmpty) return;

    // Don't show loading spinner - refresh silently in background
    try {
      // Process in chunks to avoid overwhelming the server/network
      // Chunk size of 3 means 3 friends at a time (9 API calls)
      const int chunkSize = 3;
      for (var i = 0; i < listToUse.length; i += chunkSize) {
        final end = (i + chunkSize < listToUse.length)
            ? i + chunkSize
            : listToUse.length;
        final chunk = listToUse.sublist(i, end);

        await Future.wait(chunk.map((friend) async {
          final friendId = friend['friend_id'] as int;
          try {
            final results = await Future.wait([
              _apiService.getFriendProfile(friendId,
                  forceRefresh: forceRefresh),
              _apiService
                  .getFriendCharacterMoodState(friendId,
                      forceRefresh: forceRefresh)
                  .catchError((_) => <String, dynamic>{}),
              _apiService
                  .getFriendMoodLogs(friendId)
                  .catchError((_) => <dynamic>[]),
            ]);

            _friendMoodCache[friendId] = {
              'profile': results[0],
              'characterState': results[1],
              'moodLogs': results[2],
            };
          } catch (e) {
            debugPrint('Error refreshing mood data for friend $friendId: $e');
          }
        }));

        // Update UI after each chunk
        if (mounted) {
          setState(() {});
        }
      }

      // Save updated cache to persistent storage
      // Convert int keys to string for JSON serialization
      final cacheToSave =
          _friendMoodCache.map((key, value) => MapEntry(key.toString(), value));
      await CacheService().set('social_mood_data', cacheToSave);
    } catch (e) {
      debugPrint('Error refreshing mood cache: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_friends.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      // Load friends list from cache first
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'social_data',
        maxAge: CacheService.shortCache,
      );

      // Load mood cache from persistent storage
      // Only load from cache if we are not forcing a refresh
      Map<String, dynamic>? cachedMoods;
      if (!forceRefresh) {
        cachedMoods = await CacheService().get<Map<String, dynamic>>(
          'social_mood_data',
          maxAge: CacheService.mediumCache,
        );
      }

      if (cachedMoods != null) {
        _friendMoodCache = cachedMoods.map((key, value) =>
            MapEntry(int.parse(key), value as Map<String, dynamic>));
      }

      if (cachedData != null && mounted) {
        setState(() {
          _friends = cachedData['friends'] ?? [];
          _friendRequests = cachedData['requests'] ?? [];
          _sentRequests = cachedData['sentRequests'] ?? [];
          _isLoading = false;
        });
      }

      // Fetch fresh data in background
      final friends = await _apiService.getFriends();
      final requests = await _apiService.getReceivedFriendRequests();
      final sent = await _apiService.getSentFriendRequests();

      // Update state with fresh data
      if (mounted) {
        setState(() {
          _friends = friends;
          _friendRequests = requests;
          _sentRequests = sent;
          _isLoading = false;
        });
      }

      // Update cache
      await CacheService().set('social_data', {
        'friends': friends,
        'requests': requests,
        'sentRequests': sent,
      });

    // Always fetch fresh mood details in background
    if (friends.isNotEmpty) {
      await _refreshMoodCache(friendsList: friends, forceRefresh: forceRefresh);
    }
    } catch (e) {
      debugPrint('Error loading social data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeProvider.primaryColor.withOpacity(0.08),
                  themeProvider.secondaryColor.withOpacity(0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(themeProvider),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: themeProvider.primaryColor,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: EdgeInsets.all(4.w),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 12.h),
                            child: const Text('Friends'),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 12.h),
                            child: const Text('Requests'),
                          ),
                        ),
                        Tab(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 12.h),
                            child: const Text('Sent'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab Views
                  Expanded(
                    child: _isLoading
                        ? _buildSkeletonLoader()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              KeepAliveWrapper(child: _buildFriendsTab()),
                              KeepAliveWrapper(child: _buildRequestsTab()),
                              KeepAliveWrapper(child: _buildSentTab()),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendFriendRequest(String email) async {
    try {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending friend request...')),
      );

      await _apiService.sendFriendRequest(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Friend request sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // Refresh sent requests
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showAddFriendDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your friend\'s email address to send them a request.'),
            SizedBox(height: 16.h),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'friend@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
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
              if (emailController.text.isNotEmpty) {
                _sendFriendRequest(emailController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Send Request'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: EdgeInsets.all(20.0.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social Hub',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  Text(
                    'Connect with friends',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: _showAddFriendDialog,
              icon: Icon(
                Icons.person_add_rounded,
                color: themeProvider.primaryColor,
                size: 24.sp,
              ),
              tooltip: 'Add Friend',
            ),
          ),
        ],
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
      onRefresh: () => _loadData(forceRefresh: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card (Like Progress Screen)
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Community',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_friends.length} Friends Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Friends List',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return _buildFriendCard(friend);
              },
            ),
          ],
        ),
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          return _buildSentRequestCard(request);
        },
      ),
    );
  }

  // ✨ Professional skeleton loader (like Instagram/Facebook)
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: SkeletonLoader.card(
            height: 140.h,
            width: double.infinity,
          ),
        );
      },
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
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFD700); // Gold
      case 'calm':
        return const Color(0xFF4ECDC4); // Turquoise
      case 'tired':
        return const Color(0xFF95A5A6); // Gray
      case 'anxious':
        return const Color(0xFFFFA500); // Orange
      case 'sad':
        return const Color(0xFF9575CD); // Purple
      case 'angry':
        return const Color(0xFFE74C3C); // Red
      default:
        return AppColors.primary;
    }
  }

  // Removed _getMoodEmoji for minimalistic design

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final String friendName =
        '${friend['friend_first_name'] ?? ''} ${friend['friend_last_name'] ?? ''}'
            .trim();
    final int friendId = friend['friend_id'];

    // Get cached mood data - already loaded in _loadData
    final cachedData = _friendMoodCache[friendId];
    final profile = cachedData?['profile'] ?? {};
    final moodLogs = (cachedData?['moodLogs'] ?? []) as List<dynamic>;

    // ✅ FIX: Sort mood logs by timestamp (most recent first)
    final sortedMoodLogs = List<dynamic>.from(moodLogs)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['logged_at'] ?? '');
        final dateB = DateTime.parse(b['logged_at'] ?? '');
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

    // Use most recent mood log (no default - empty string if no mood)
    String currentMood = '';
    if (sortedMoodLogs.isNotEmpty) {
      currentMood = sortedMoodLogs.first['mood'] ?? '';
    }

    final Color moodColor =
        currentMood.isNotEmpty ? _getMoodColor(currentMood) : Colors.grey;

    // Get character info
    final character = profile['character'];
    final gender = character?['gender'] ?? 'boy';
    final characterNumber = character?['number'] ?? 1;

    // Map mood to GIF mood state
    String moodState;
    switch (currentMood.toLowerCase()) {
      case 'happy':
        moodState = 'Happy';
        break;
      case 'calm':
        moodState = 'Calm';
        break;
      case 'tired':
        moodState = 'Tired';
        break;
      case 'anxious':
        moodState = 'Anxious';
        break;
      case 'sad':
        moodState = 'Sad';
        break;
      case 'angry':
        moodState = 'Angry';
        break;
      case 'unknown':
      default:
        moodState = ''; // No fallback - show placeholder if no mood
    }

    final genderPrefix =
        (gender as String).toLowerCase() == 'girl' ? 'Girl' : 'Boy';
    final String firstLetter =
        friendName.isNotEmpty ? friendName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () async {
        await context
            .push('/friend/$friendId?name=${Uri.encodeComponent(friendName)}');
        // ✅ FIX: Reload entire friends list when returning from friend profile
        await _loadData(forceRefresh: true);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24.r), // More rounded like Progress
          boxShadow: [
            BoxShadow(
              color: moodColor.withOpacity(0.15),
              blurRadius: 15.r,
              offset: Offset(0, 5.h),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Character mood GIF (square) - using cached data
            if (character != null)
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: moodState.isEmpty
                      ? Icon(Icons.person,
                          size: 32.sp, color: AppColors.textSecondary)
                      : ImageCacheManager().buildCachedImage(
                          assetPath:
                              'assets/images/${genderPrefix}_Gif_33FPS/$moodState$genderPrefix$characterNumber.gif',
                          fit: BoxFit.cover,
                        ),
                ),
              )
            else
              // Fallback to gradient with initial
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendName.isEmpty ? 'Unknown' : friendName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16.sp, color: AppColors.gameYellow),
                      SizedBox(width: 4.w),
                      Text(
                        'Level ${friend['friend_level'] ?? 1}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: moodColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      currentMood.isEmpty
                          ? 'No mood logged'
                          : currentMood.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: moodColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName.isEmpty ? 'Unknown' : senderName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Wants to connect',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.stateThriving.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      Icon(Icons.check_rounded, color: AppColors.stateThriving),
                  onPressed: () => _acceptFriendRequest(request['id']),
                  iconSize: 24.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.error),
                  onPressed: () => _rejectFriendRequest(request['id']),
                  iconSize: 24.sp,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _cancelFriendRequest(request['id']),
            icon:
                Icon(Icons.close_rounded, size: 18.sp, color: AppColors.error),
            label: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
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
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          children: [
            _buildInfoCard(
              icon: Icons.task_alt,
              title: 'Task Accountability',
              description:
                  'Share your daily tasks and keep each other motivated!',
              color: AppColors.primary,
            ),
            SizedBox(height: 32.h),

            // Your Tasks Today
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.secondary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.person,
                      color: AppColors.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Your Tasks Today',
                  style: TextStyle(
                    fontSize: 20.sp,
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

            SizedBox(height: 32.h),

            // Friend's Shared Tasks
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (friend['friend_first_name'] != null &&
                              friend['friend_first_name']
                                  .toString()
                                  .isNotEmpty)
                          ? friend['friend_first_name']
                              .toString()[0]
                              .toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "${friend['friend_first_name'] ?? 'Friend'}'s Tasks",
                    style: TextStyle(
                      fontSize: 20.sp,
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

            SizedBox(height: 32.h),

            // Send Encouragement Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _sendEncouragement(friend),
                icon: Icon(Icons.favorite_rounded, size: 22.sp),
                label: Text(
                  'Send Encouragement',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
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
        // print('Error loading friend tasks: $e');
        // If API endpoint doesn't exist yet, friendTasks stays empty
      }

      return {
        'myTasks': myTodayTasks,
        'friendTasks': friendTasks,
      };
    } catch (e) {
      // print('Error loading accountability tasks: $e');
      return {
        'myTasks': [],
        'friendTasks': [],
      };
    }
  }

  Widget _buildEmptyTaskState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(24.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
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
                        AppColors.primary.withOpacity(0.2),
                        AppColors.secondary.withOpacity(0.2),
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
                      AppColors.gameYellow.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gameYellow.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gameYellow.withOpacity(0.15),
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
                        color: AppColors.gameYellow.withOpacity(0.2),
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
                      'Keep Each Other Motivated',
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
        // print('Error loading friend streak: $e');
        // If API endpoint doesn't exist yet, friendStreak stays empty
      }

      return {
        'myStreak': myStreak,
        'friendStreak': friendStreak,
      };
    } catch (e) {
      // print('Error loading streak data: $e');
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
                    AppColors.primary.withOpacity(0.2),
                    AppColors.secondary.withOpacity(0.2),
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
                color: AppColors.primary.withOpacity(0.3),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCompleted
              ? color.withOpacity(0.3)
              : Colors.grey[200]!,
          width: isCompleted ? 2.w : 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? color.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
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
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
          ],
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 16.h : 0,
              ),
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: item['color'].withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: item['color'],
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item['color'],
                            item['color'].withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: item['color'].withOpacity(0.3),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Text(
                        '${item['days']} days',
                        style: TextStyle(
                          fontSize: 14.sp,
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
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
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
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: color,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$daysLeft',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'days',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Progress Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10.h,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Progress Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14.sp,
                      color: color,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'On Track',
                      style: TextStyle(
                        fontSize: 12.sp,
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
              // SnackBar removed for cleaner UI
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
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



  Future<void> _acceptFriendRequest(int requestId) async {
    _actionDebouncer.run(() async {
      try {
        await _apiService.acceptFriendRequest(requestId);
        if (mounted) {
          _loadData();
        }
      } catch (e) {
        debugPrint('Error accepting friend request: $e');
        if (mounted) {
          _loadData();
        }
      }
    });
  }

  Future<void> _rejectFriendRequest(int requestId) async {
    _actionDebouncer.run(() async {
      try {
        await _apiService.rejectFriendRequest(requestId);
        if (mounted) {
          _loadData();
        }
      } catch (e) {
        debugPrint('Error rejecting friend request: $e');
        if (mounted) {
          _loadData();
        }
      }
    });
  }

  Future<void> _cancelFriendRequest(int requestId) async {
    _actionDebouncer.run(() async {
      try {
        await _apiService.cancelFriendRequest(requestId);
        if (mounted) {
          _loadData();
        }
      } catch (e) {
        debugPrint('Error cancelling friend request: $e');
        if (mounted) {
          _loadData();
        }
      }
    });
  }

  Future<void> _removeFriend(int friendId) async {
    _actionDebouncer.run(() async {
      try {
        await _apiService.removeFriend(friendId);
        if (mounted) {
          _loadData();
        }
      } catch (e) {
        debugPrint('Error removing friend: $e');
        if (mounted) {
          _loadData();
        }
      }
    });
  }

  Future<void> _sendEncouragement(Map<String, dynamic> friend) async {
    _actionDebouncer.run(() async {
      try {
        final friendId = friend['friend_id'];
        await _apiService.sendEncouragement(
          friendId,
          'Keep up the great work!',
        );

        if (mounted) {
          // SnackBar removed for cleaner UI
        }
      } catch (e) {
        debugPrint('Error sending encouragement: $e');
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
    });
  }

  Future<void> _viewFriendProfile(Map<String, dynamic> friend) async {
    try {
      final friendUserId = friend['friend_user_id'] ?? friend['user_id'];
      if (friendUserId == null) return;

      final profile =
          await _actionDebouncer.runAsync<Map<String, dynamic>>(() async {
        return await _apiService.getFriendProfile(friendUserId);
      });

      if (!mounted) return;

      // Show profile dialog with character
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${profile?['first_name']} ${profile?['last_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Character image/gif
              if (profile?['character'] != null) ...[
                Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      profile?['character']['name'] ?? 'Character',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                profile?['email'] ?? '',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 8.h),
              if (profile?['interests'] != null &&
                  profile!['interests'].isNotEmpty) ...[
                const Divider(),
                SizedBox(height: 8.h),
                const Text(
                  'Interests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: (profile!['interests'] as List).map((interest) {
                    return Chip(
                      label: Text(interest['name'] ?? ''),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
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
      // print('Error viewing friend profile: $e');
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

              await _actionDebouncer.run(() async {
                try {
                  final friendId = friend['friend_id'];
                  await _apiService.sendMessage(
                    friendId,
                    messageController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    // SnackBar removed for cleaner UI
                  }
                } catch (e) {
                  // print('Error sending message: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to send message'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              });
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
