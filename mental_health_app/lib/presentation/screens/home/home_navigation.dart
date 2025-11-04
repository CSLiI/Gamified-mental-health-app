import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../mood/mood_screen.dart';
import '../journal/journal_screen.dart';
import '../todos/todo_screen.dart';
import '../profile/profile_screen.dart';
import '../../../data/services/api_service.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  final _apiService = ApiService();
  int _currentIndex = 0;
  String? _lastSelectedMood; // Store mood at navigation level
  bool _isInitialLoad = true; // Track first load to prevent flash
  bool _moodLoaded = false; // Track if mood has been loaded

  // Mood colors matching mood_screen.dart
  final Map<String, Color> _moodColors = {
    'happy': const Color(0xFFFFD54F), // Yellow
    'calm': const Color(0xFF42A5F5), // Blue
    'tired': const Color(0xFF78909C), // Blue Grey
    'anxious': const Color(0xFFFFA726), // Orange
    'sad': const Color(0xFF9575CD), // Purple
    'angry': const Color(0xFFEF5350), // Red
  };

  // Get current mood color or default
  Color get _currentMoodColor {
    if (_lastSelectedMood != null &&
        _moodColors.containsKey(_lastSelectedMood)) {
      return _moodColors[_lastSelectedMood]!;
    }
    return const Color(0xFF5CACEE); // Default blue
  }

  // Get lighter version for background gradient (similar to character card)
  Color get _currentMoodColorLight {
    final lightestColor =
        Color.lerp(_currentMoodColor, Colors.white, 0.7) ?? _currentMoodColor;
    return lightestColor.withValues(alpha: 0.9);
  }

  // Get slightly darker version for gradient (similar to character card)
  Color get _currentMoodColorDark {
    final brighterColor =
        Color.lerp(_currentMoodColor, Colors.white, 0.5) ?? _currentMoodColor;
    return brighterColor.withValues(alpha: 0.9);
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onMoodSelected(String mood) async {
    print('🎭 NAVIGATION: Mood selected: "$mood" (length: ${mood.length})');
    print('🔍 NAVIGATION: Mood bytes: ${mood.codeUnits}');

    // Save to SharedPreferences with user-specific key
    try {
      // Get current user ID
      final user = await _apiService.getCurrentUser();
      final userId = user['id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mood_$userId', mood);
      final saved = prefs.getString('last_selected_mood_$userId');
      print('💾 NAVIGATION: Saved mood for user $userId: "$mood"');
      print('✅ NAVIGATION: Read back mood: "$saved"');

      // Update local state
      setState(() {
        _lastSelectedMood = mood;
      });

      // DON'T auto-switch back to Home tab - let user stay on mood screen
    } catch (e) {
      print('Error saving mood: $e');
    }
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Start loading immediately but don't block
    _loadInitialMood();
    _screens = [
      HomeScreen(onNavigate: _onTabSelected),
      MoodScreen(
        characterId: 1, // Replace with the actual character ID
        characterGender: 'Boy', // Replace with the actual character gender
        characterNumber: 1, // Replace with the actual character number
        onMoodSelected: _onMoodSelected, // Connect the callback
      ),
      const JournalScreen(),
      const TodoScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload on subsequent dependency changes (not initial load)
    if (!_isInitialLoad) {
      print('🔄 NAVIGATION: Dependencies changed, reloading mood...');
      _loadInitialMood();
    }
    _isInitialLoad = false;
  }

  // Load mood fast to prevent any flash
  Future<void> _loadInitialMood() async {
    if (_moodLoaded) return; // Don't reload if already loaded

    try {
      // Get current user ID
      final user = await _apiService.getCurrentUser();
      final userId = user['id'];

      // Load from cache (fast - no API call needed)
      final prefs = await SharedPreferences.getInstance();
      final cachedMood = prefs.getString('last_selected_mood_$userId');

      if (cachedMood != null) {
        if (mounted) {
          setState(() {
            _lastSelectedMood = cachedMood;
            _moodLoaded = true;
          });
        }
        print(
            '⚡ NAVIGATION: Loaded cached mood for user $userId: "$cachedMood"');

        // Then update from backend in background (don't await)
        _updateFromBackend(userId);
      } else {
        // No cache, fetch from backend FIRST before showing UI
        print('ℹ️ NAVIGATION: No cached mood, fetching from backend...');

        try {
          final recentMoods = await _apiService.getMoodLogs(limit: 1);
          if (recentMoods.isNotEmpty && mounted) {
            final latestMood = recentMoods[0]['mood'] as String;
            setState(() {
              _lastSelectedMood = latestMood;
              _moodLoaded = true;
            });
            print(
                '✅ NAVIGATION: Loaded mood from backend for user $userId: "$latestMood"');

            // Update cache
            await prefs.setString('last_selected_mood_$userId', latestMood);
          } else {
            // No mood logs, use default
            if (mounted) {
              setState(() {
                _moodLoaded = true;
              });
            }
            print('ℹ️ NAVIGATION: No mood logs found, using default');
          }
        } catch (backendError) {
          print('⚠️ NAVIGATION: Failed to fetch from backend: $backendError');
          // Show UI with default color if backend fails
          if (mounted) {
            setState(() {
              _moodLoaded = true;
            });
          }
        }
      }
    } catch (e) {
      print('❌ NAVIGATION: Error loading initial mood: $e');
      // Still mark as loaded to show UI even if error
      if (mounted) {
        setState(() {
          _moodLoaded = true;
        });
      }
    }
  }

  // Update mood from backend (can run in background)
  Future<void> _updateFromBackend(int userId) async {
    try {
      final recentMoods = await _apiService.getMoodLogs(limit: 1);
      if (recentMoods.isNotEmpty && mounted) {
        final latestMood = recentMoods[0]['mood'] as String;

        // Only update if different from cached
        if (_lastSelectedMood != latestMood) {
          setState(() {
            _lastSelectedMood = latestMood;
          });
          print(
              '🔄 NAVIGATION: Updated mood from backend for user $userId: "$latestMood"');
        }

        // Update cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_selected_mood_$userId', latestMood);
      }
    } catch (e) {
      print('⚠️ NAVIGATION: Failed to update from backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Block rendering until mood is loaded to prevent flash
    if (!_moodLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _buildMainScaffold();
  }

  Widget _buildMainScaffold() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Light gradient background - fixed, not mood-based
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FE), // Very light blue-grey
              Color(0xFFE8EAFC), // Slightly darker blue-grey
            ],
          ),
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _currentMoodColorLight, // Character card style gradient
              _currentMoodColorDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _currentMoodColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: _currentMoodColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.mood_outlined,
                  activeIcon: Icons.mood,
                  label: 'Mood',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book,
                  label: 'Journal',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.checklist_outlined,
                  activeIcon: Icons.checklist,
                  label: 'Quests',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    // Gamified nav item with glow effect - colors based on mood
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gamified container with glow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? _currentMoodColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(
                        color: _currentMoodColor,
                        width: 2,
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _currentMoodColor.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : const Color(0xFF6B8BA8),
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
                color: isActive ? _currentMoodColor : const Color(0xFF6B8BA8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
