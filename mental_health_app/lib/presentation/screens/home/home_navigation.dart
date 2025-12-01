import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/character_provider.dart';
import 'home_screen.dart';
import '../mood/mood_screen.dart';
import '../social/social_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;
  final Debouncer _tabDebouncer = Debouncer(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    // Load initial data - UserProvider first to avoid redundant API calls
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load user first (single API call, cached)
      await context.read<UserProvider>().loadUser();
      // Then load mood and character (they use cached userId)
      context.read<MoodProvider>().loadMood();
      context.read<CharacterProvider>().loadCharacter();
      _prefetchCritical();
    });
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
    print('🎭 NAVIGATION: Mood selected: "$mood"');
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
    return Consumer2<MoodProvider, CharacterProvider>(
      builder: (context, moodProvider, characterProvider, child) {
        final screens = [
          HomeScreen(onNavigate: _onTabSelected),
          const SocialScreen(),
          const ProgressScreen(),
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
                .withValues(alpha: 0.9);
        final currentMoodColorDark =
            Color.lerp(currentMoodColor, Colors.white, 0.5)!
                .withValues(alpha: 0.9);

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
                  color: currentMoodColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: currentMoodColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? moodColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border:
                    isActive ? Border.all(color: moodColor, width: 2) : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: moodColor.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : const Color(0xFF2D3748),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
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
