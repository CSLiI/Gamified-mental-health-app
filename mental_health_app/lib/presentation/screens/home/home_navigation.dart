import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import 'home_screen.dart';
import '../mood/mood_screen.dart';
import '../journal/journal_screen.dart';
import '../todos/todo_screen.dart';
import '../profile/profile_screen.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;
  String? _lastSelectedMood; // Store mood at navigation level

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

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mood', mood);
      final saved = prefs.getString('last_selected_mood');
      print('💾 NAVIGATION: Saved mood: "$mood"');
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Baby blue gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB0E0FF), // Lighter baby blue at top
              Color(0xFF89CFF0), // Baby blue at bottom
            ],
          ),
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5CACEE), // Darker baby blue
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.white.withAlpha(50),
              width: 1,
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

    // Gamified nav item with glow effect
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
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(
                        color: const Color(0xFF5CACEE),
                        width: 2,
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF5CACEE) : Colors.white,
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
                color: isActive ? Colors.white : Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
