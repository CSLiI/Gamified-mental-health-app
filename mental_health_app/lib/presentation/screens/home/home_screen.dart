import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../widgets/level_up_dialog.dart';
import '../../../core/utils/image_cache_manager.dart';

import '../../../core/utils/debouncer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final Debouncer _navDebouncer = Debouncer(milliseconds: 350);
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _characterState;
  Map<String, dynamic>? _levelProgress;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    // Fast load: show cached immediately, then background refresh
    _loadCachedFirst();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterProvider>().loadCharacter();
      context.read<MoodProvider>().loadMood();
      _precacheCharacterGifs();
    });
  }

  /// Display cached data instantly without blocking, then refresh in background
  void _loadCachedFirst() {
    // Non-blocking cache read for instant display
    CacheService()
        .get<Map<String, dynamic>>(
      'home_data',
      maxAge: const Duration(minutes: 10),
    )
        .then((cachedData) {
      if (cachedData != null && mounted) {
        setState(() {
          _userData = cachedData['user'];
          _characterState = cachedData['characterState'];
          _levelProgress = cachedData['levelProgress'];
          _isLoading = false;
        });
      }
    });

    // Parallel background refresh
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Call getLevelProgress FIRST to sync level in DB before getting user data
      Map<String, dynamic>? levelProgress;
      try {
        levelProgress = await _apiService.getLevelProgress();
      } catch (e) {
        levelProgress = {};
      }

      // Now fetch user and character state in parallel
      final results = await Future.wait([
        _apiService.getFreshUserData(),
        _apiService.getCharacterMoodState().catchError((e) {
          return <String, dynamic>{};
        }),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final characterState = results[1] as Map<String, dynamic>?;

      // Update cache
      await CacheService().set('home_data', {
        'user': user,
        'characterState': characterState,
        'levelProgress': levelProgress,
      });

      if (mounted) {
        setState(() {
          _userData = user;
          _characterState = characterState;
          _levelProgress = levelProgress;
          _isLoading = false;
        });
        
        // Check for low mood and show helpline dialog if needed
        final moodProvider = context.read<MoodProvider>();
        final moodScore = moodProvider.moodScore;
        
        if (moodScore < 40) {
          final notificationProvider = context.read<NotificationProvider>();
          if (!notificationProvider.hasShownLowMoodAlert) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showHelpDialog();
              }
            });
            
            notificationProvider.addSystemNotification(
              title: "We're here for you",
              message: "It seems you're going through a tough time. Tap here for support resources.",
              type: NotificationType.systemAlert,
              redirectRoute: '/home?initialIndex=4&action=help',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _precacheCharacterGifs() async {
    try {
      // Use currently loaded character info if available
      final characterProvider = context.read<CharacterProvider>();
      await ImageCacheManager().preloadCharacter(
        context,
        characterProvider.characterGender,
        characterProvider.characterNumber,
      );
    } catch (_) {
      // Best-effort precache; ignore failures
    }
  }

  Future<void> _checkLevelUpOnLoad() async {
    try {
      // Small delay to let UI settle
      await Future.delayed(const Duration(milliseconds: 500));

      final result = await _apiService.checkLevelUp();

      if (result['leveled_up'] == true && mounted) {
        // Show level-up celebration
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LevelUpDialog(
            oldLevel: result['old_level'],
            newLevel: result['new_level'],
            milestoneXp: result['milestone_xp'] ?? 0,
            rewardsUnlocked: result['rewards_unlocked'] ?? [],
            petsUnlocked: result['pets_unlocked'] ?? [],
          ),
        );

        // Reload data after celebration
        if (mounted) {
          _loadData();
        }
      }
    } catch (e) {
      // Level up check failed silently
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
        moodState = 'Tired'; // Fixed: Use Tired GIF for tired mood
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

  String _getMoodMessage(String? mood) {
    switch (mood?.toLowerCase() ?? '') {
      case 'happy':
      case 'thriving':
        return "Great job! Keep up the positive energy!";
      case 'calm':
      case 'content':
        return "Glad you're feeling balanced. Enjoy the peace.";
      case 'tired':
        return "It's okay to rest. Take a break if you need it.";
      case 'anxious':
      case 'struggling':
        return "Take a deep breath. You've got this.";
      case 'sad':
        return "Be gentle with yourself. Tomorrow is a new day.";
      case 'angry':
      case 'needs_support':
        return "It's okay to feel this way. Try to unwind.";
      default:
        return "How are you feeling today?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
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
            child: _isLoading
                ? _buildHomeSkeleton()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadData();
                      if (mounted) {
                        await context.read<MoodProvider>().loadMood(forceRefresh: true);
                      }
                    },
                    color: themeProvider.primaryColor,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(24.0.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 24.h),
                          _buildCharacterCard(),
                          SizedBox(height: 24.h),
                          _buildQuickActions(),
                          SizedBox(height: 24.h),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHomeSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.text(width: 150.w, height: 20.h),
                  SizedBox(height: 8.h),
                  SkeletonLoader.text(width: 180.w, height: 32.h),
                ],
              ),
              SkeletonLoader.character(size: 50.sp),
            ],
          ),
          SizedBox(height: 24.h),
          // Character card skeleton
          SkeletonLoader.card(height: 400.h),
          SizedBox(height: 24.h),
          // Quick actions skeleton
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 100.h)),
              SizedBox(width: 16.w),
              Expanded(child: SkeletonLoader.card(height: 100.h)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 100.h)),
              SizedBox(width: 16.w),
              Expanded(child: SkeletonLoader.card(height: 100.h)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = _userData?['first_name'] ?? 'User';
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  onPressed: () => context.go('/notifications'),
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final count = notifProvider.unreadCount;
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.w,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Consumer<MoodProvider>(
          builder: (context, moodProvider, child) {
            final currentMood = moodProvider.currentMood;
            return Text(
              _getMoodMessage(currentMood),
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    return Consumer3<MoodProvider, CharacterProvider, ThemeProvider>(
      builder:
          (context, moodProvider, characterProvider, themeProvider, child) {
        // Wait for character to load to prevent default GIF from showing
        if (characterProvider.isLoading) {
          return SkeletonLoader.card(height: 400.h);
        }

        final mood = moodProvider.currentMood;
        // Use Grey/Neutral color if mood is null (no logs yet)
        final moodColor = mood != null ? moodProvider.getMoodColor() : Colors.grey;

        // Use provider for real-time updates
        final moodScore = moodProvider.moodScore;
        final firstName = _userData?['first_name'] ?? 'User';

        // Parse level with type safety
        int level = 1;
        final levelProgressMap = _levelProgress;
        final userDataMap = _userData;

        if (levelProgressMap != null && levelProgressMap['level'] != null) {
          if (levelProgressMap['level'] is int) {
            level = levelProgressMap['level'] as int;
          } else if (levelProgressMap['level'] is String) {
            level = int.tryParse(levelProgressMap['level'] as String) ?? 1;
          }
        } else if (userDataMap != null && userDataMap['level'] != null) {
          if (userDataMap['level'] is int) {
            level = userDataMap['level'] as int;
          } else if (userDataMap['level'] is String) {
            level = int.tryParse(userDataMap['level'] as String) ?? 1;
          }
        }

        // Parse XP with type safety
        int xpInCurrentLevel = 0;
        if (levelProgressMap != null &&
            levelProgressMap['xp_in_current_level'] != null) {
          if (levelProgressMap['xp_in_current_level'] is int) {
            xpInCurrentLevel = levelProgressMap['xp_in_current_level'] as int;
          } else if (levelProgressMap['xp_in_current_level'] is String) {
            xpInCurrentLevel = int.tryParse(
                    levelProgressMap['xp_in_current_level'] as String) ??
                0;
          }
        }

        int xpForNextLevel = 100;
        if (levelProgressMap != null &&
            levelProgressMap['xp_for_next_level'] != null) {
          if (levelProgressMap['xp_for_next_level'] is int) {
            xpForNextLevel = levelProgressMap['xp_for_next_level'] as int;
          } else if (levelProgressMap['xp_for_next_level'] is String) {
            xpForNextLevel =
                int.tryParse(levelProgressMap['xp_for_next_level'] as String) ??
                    100;
          }
        }

        final double xpProgress = xpForNextLevel > 0
            ? (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0)
            : 0.0;

        // Get equipped banner gradient and colors
        final bannerGradient = themeProvider.getBannerGradient();
        final hasBanner = themeProvider.equippedBanner != null;
        final bannerColor1 = hasBanner
            ? (themeProvider.equippedBanner!['color1'] as Color?)
            : null;

        print(
            '🎨 Banner check: hasBanner=$hasBanner, bannerColor1=$bannerColor1');

        // Enhanced styling based on equipped banner
        final double cardRadius = hasBanner && bannerColor1 != null ? 24 : 32;

        final backgroundDecoration = hasBanner && bannerColor1 != null
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(moodColor, Colors.white, 0.6)!
                        .withOpacity(0.95),
                    Color.lerp(moodColor, Colors.white, 0.4)!
                        .withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(cardRadius.r),
                boxShadow: [
                  BoxShadow(
                    color: bannerColor1.withOpacity(0.3),
                    blurRadius: 25.r,
                    offset: Offset(0, 10.h),
                    spreadRadius: 5.r,
                  ),
                  BoxShadow(
                    color: moodColor.withOpacity(0.1),
                    blurRadius: 15.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              )
            : BoxDecoration(
                color: Color.lerp(moodColor, Colors.white, 0.8)!, // Solid pastel color
                borderRadius: BorderRadius.circular(cardRadius.r), // Even rounder
                boxShadow: [
                  BoxShadow(
                    color: moodColor.withOpacity(0.15), // Very gentle shadow
                    blurRadius: 25.r,
                    offset: Offset(0, 10.h),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 10.r,
                    offset: Offset(-2, -2.h),
                    spreadRadius: 0,
                  ),
                ],
              );

        return Container(
          decoration: backgroundDecoration,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius.r),
            border: hasBanner && bannerColor1 != null
                ? Border.all(color: bannerColor1, width: 3.w)
                : Border.all(color: Colors.white.withOpacity(0.8), width: 2.w),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
              children: [
                if (bannerGradient != null)
                  Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: bannerGradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced character GIF container with banner styling
                  Container(
                    decoration: hasBanner &&
                            bannerGradient != null &&
                            bannerColor1 != null
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            gradient: bannerGradient,
                            boxShadow: [
                              BoxShadow(
                                color: bannerColor1.withOpacity(0.4),
                                blurRadius: 15.r,
                                offset: Offset(0, 5.h),
                                spreadRadius: 2.r,
                              ),
                            ],
                          )
                        : null,
                    padding: hasBanner && bannerGradient != null
                        ? EdgeInsets.all(4.w)
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(hasBanner ? 16.r : 15.r),
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Removed grey background
                          border: hasBanner
                              ? Border.all(
                                  color: Colors.white,
                                  width: 3.w,
                                )
                              : null,
                          borderRadius:
                              BorderRadius.circular(hasBanner ? 16.r : 15.r),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(hasBanner ? 13.r : 15.r),
                          child: ImageCacheManager().buildCachedImage(
                            assetPath: _getCharacterGifPath(
                              mood ?? 'calm',
                              characterProvider.characterGender,
                              characterProvider.characterNumber,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [

                            Text(
                              firstName,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Color.lerp(moodColor, Colors.black, 0.8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Level $level',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Color.lerp(
                                          moodColor, Colors.black, 0.15),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$xpInCurrentLevel / $xpForNextLevel XP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Color.lerp(moodColor, Colors.black, 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: xpProgress.clamp(0.0, 1.0),
                            minHeight: 8.h,
                            backgroundColor:
                                Color.lerp(moodColor, Colors.white, 0.7)!
                                    .withOpacity(0.5),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(moodColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            mood != null ? 'Mood: $mood' : 'Mood: ---',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(moodColor, Colors.black, 0.7),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${moodScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Color.lerp(moodColor, Colors.black, 0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: moodScore / 100,
                      backgroundColor: Color.lerp(moodColor, Colors.white, 0.7)!
                          .withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                      minHeight: 12.h,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
      },
    );
  }


  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 24.sp, color: Theme.of(context).colorScheme.onSurface),
            SizedBox(width: 8.w),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 1.0,
          children: [
            _buildActionCard(
              icon: Icons.mood_rounded,
              label: 'Log Mood',
              color: const Color(0xFFB39DDB), // Muted Lavender
              index: 1,
            ),
            _buildActionCard(
              icon: Icons.auto_stories_rounded,
              label: 'Journal',
              color: const Color(0xFFA5D6A7), // Sage Green
              index: 2,
            ),
            _buildActionCard(
              icon: Icons.assignment_rounded,
              label: 'Quests',
              color: const Color(0xFFFFCC80), // Soft Orange
              index: 3,
            ),
            _buildActionCard(
              icon: Icons.pets_rounded,
              label: 'My Companion',
              color: const Color(0xFF90CAF9), // Soft Blue
              index: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required int index,
  }) {
    final Color darkerColor = Color.lerp(color, Colors.black, 0.6) ?? color;
    final isPetCard = label == 'My Companion';

    return Container(
      decoration: BoxDecoration(
        color: color, // Solid color
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25), // Softer shadow
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 8.r,
            offset: Offset(-2, -2.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _navDebouncer.run(() {
              // Map labels to new navbar indices
              // New navbar: [Home=0, Social=1, Progress=2, Mood=3, Profile=4]
              if (label == 'Log Mood') {
                widget.onNavigate?.call(3); // Mood tab
              } else if (label == 'Journal') {
                context.go('/journal'); // Navigate to journal route
              } else if (label == 'Quests') {
                context.go('/todos'); // Navigate to todos route
              } else if (label == 'Rewards') {
                widget.onNavigate?.call(2); // Progress tab
              } else if (label == 'My Companion') {
                context.push('/pet-care'); // Navigate to pet care screen
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : darkerColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? darkerColor
                        : Colors.white,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : darkerColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('We\'re Here for You'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Important Disclaimer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
            ),
            SizedBox(height: 12),
            Text(
              'This app is a tool for self-care and habit building. It is NOT a replacement for professional mental health treatment or therapy.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Text(
              'If you are in danger or experiencing a mental health emergency, please contact:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text('• Befrienders KL (24/7): 03-7627 2929', style: TextStyle(fontSize: 14)),
            Text('• Talian Kasih (24/7): 15999', style: TextStyle(fontSize: 14)),
            Text('• Emergency: 999', style: TextStyle(fontSize: 14)),
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
  }
}
