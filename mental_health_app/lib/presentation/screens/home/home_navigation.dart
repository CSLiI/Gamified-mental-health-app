import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/providers/theme_provider.dart';
import 'home_screen.dart';
import '../mood/mood_screen.dart';
import '../social/social_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeNavigation extends StatefulWidget {
  final int initialIndex;
  final int initialTabIndex;
  
  const HomeNavigation({
    super.key, 
    this.initialIndex = 0,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  late int _currentIndex;
  final Debouncer _tabDebouncer = Debouncer(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Load initial data - UserProvider first to avoid redundant API calls
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load user first (single API call, cached)
      try {
        await context.read<UserProvider>().loadUser();

        // Load theme with EXPLICIT user ID to prevent cross-account leakage
        final userProvider = context.read<UserProvider>();
        if (userProvider.user != null) {
          await context
              .read<ThemeProvider>()
              .refreshTheme(userProvider.user!['id'] as int);
        }

        // Then load mood and character (they use cached userId)
        context.read<MoodProvider>().loadMood();
        context.read<CharacterProvider>().loadCharacter();
        _prefetchCritical();
      } catch (e) {
        // Authentication failed - redirect to login
        print('❌ HomeNavigation: Auth failed, redirecting to login: $e');
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  void didUpdateWidget(HomeNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabSelected(int index) {
    _tabDebouncer.run(() {
      setState(() {
        _currentIndex = index;
      });
      HapticFeedback.lightImpact();
    });
  }

  void _onMoodSelected(String mood) async {
    // print('🎭 NAVIGATION: Mood selected: "$mood"');
    await context.read<MoodProvider>().updateMood(mood);

    // Switch to Home tab to show the change
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  Future<void> _prefetchCritical() async {
    final api = ApiService();
    try {
      final results = await Future.wait([
        api.getCurrentUser(),
        api.getCharacterMoodState().catchError((_) => <String, dynamic>{}),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final characterState = results[1] as Map<String, dynamic>?;

      // Warm caches for fast first-paint on Home
      await CacheService().set('home_data', {
        'user': user,
        'characterState': characterState,
      });

      // Also warm social mood cache minimally with self data
      await CacheService().set('social_mood_data', {
        '${user['id']}': {
          'profile': user,
          'characterState': characterState ?? {},
          'moodLogs': [],
        }
      });
    } catch (_) {
      // Ignore errors; prefetch is best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab, go back to home instead of exiting
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // If on home tab, show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: const Text(
              'Exit Echo?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B9080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Consumer3<MoodProvider, CharacterProvider, ThemeProvider>(
        builder: (context, moodProvider, characterProvider, themeProvider, child) {
          final screens = [
            HomeScreen(onNavigate: _onTabSelected),
            const SocialScreen(),
            ProgressScreen(initialIndex: widget.initialTabIndex), // Pass tab index
            MoodScreen(
              characterId: characterProvider.characterId,
              characterGender: characterProvider.characterGender,
              characterNumber: characterProvider.characterNumber,
              onMoodSelected: _onMoodSelected,
            ),
            const ProfileScreen(),
          ];

          final currentMoodColor = moodProvider.getMoodColor();
          final currentMoodColorLight =
              Color.lerp(currentMoodColor, Colors.white, 0.7)!
                  .withOpacity(0.9);
          final currentMoodColorDark =
              Color.lerp(currentMoodColor, Colors.white, 0.5)!
                  .withOpacity(0.9);

          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeProvider.palette.background,
                    themeProvider.palette.background,
                  ],
                ),
              ),
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    currentMoodColorLight,
                    currentMoodColorDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentMoodColor.withOpacity(0.2),
                    blurRadius: 15.r,
                    offset: Offset(0, -3.h),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: currentMoodColor.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                        index: 0,
                        moodColor: currentMoodColor,
                      ),
                      _buildNavItem(
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        label: 'Social',
                        index: 1,
                        moodColor: currentMoodColor,
                      ),
                      _buildNavItem(
                        icon: Icons.emoji_events_outlined,
                        activeIcon: Icons.emoji_events,
                        label: 'Progress',
                        index: 2,
                        moodColor: currentMoodColor,
                      ),
                      _buildNavItem(
                        icon: Icons.mood_outlined,
                        activeIcon: Icons.mood,
                        label: 'Mood',
                        index: 3,
                        moodColor: currentMoodColor,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        index: 4,
                        moodColor: currentMoodColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color moodColor,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isActive ? moodColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                border:
                    isActive ? Border.all(color: moodColor, width: 2.w) : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: moodColor.withAlpha(100),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : const Color(0xFF2D3748),
                size: 24.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? moodColor : const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
