import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _apiService = ApiService();
  final _pageController = PageController();
  int _currentPage = 0;

  // Character selection variables
  List<Map<String, dynamic>> _characterOptions = [];
  int? _selectedCharacterId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupCharacterOptions();
  }

  void _setupCharacterOptions() {
    // Define character options (ID, gender, number, name, description)
    _characterOptions = [
      {
        'id': 1,
        'gender': 'Boy',
        'number': 1,
        'name': 'Calm Boy 1',
        'description': 'A focused and mindful companion for your journey',
        'color': const Color(0xFF5CACEE), // Blue
        'gifPath': 'assets/images/Boy_Gif_33FPS/CalmBoy1.gif',
      },
      {
        'id': 2,
        'gender': 'Boy',
        'number': 2,
        'name': 'Calm Boy 2',
        'description': 'A reliable friend who helps you stay grounded',
        'color': const Color(0xFF66BB6A), // Green
        'gifPath': 'assets/images/Boy_Gif_33FPS/CalmBoy2.gif',
      },
      {
        'id': 3,
        'gender': 'Girl',
        'number': 1,
        'name': 'Calm Girl 1',
        'description': 'A supportive guide for your wellness journey',
        'color': const Color(0xFFFF8EC4), // Pink
        'gifPath': 'assets/images/Girl_Gif_33FPS/CalmGirl1.gif',
      },
      {
        'id': 4,
        'gender': 'Girl',
        'number': 2,
        'name': 'Calm Girl 2',
        'description': 'An encouraging partner for your daily goals',
        'color': const Color(0xFFFFD54F), // Yellow
        'gifPath': 'assets/images/Girl_Gif_33FPS/CalmGirl2.gif',
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectCharacter() async {
    if (_selectedCharacterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a character'),
          backgroundColor: Color(0xFFFF9800), // Warning color
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find the selected character option
      final selectedCharacter = _characterOptions.firstWhere(
        (char) => char['id'] == _selectedCharacterId,
        orElse: () => _characterOptions[0],
      );

      // Send to backend API FIRST
      print(
          '🎯 Onboarding: Sending character ${_selectedCharacterId} to backend...');
      await _apiService.chooseCharacter(_selectedCharacterId!);
      print('✅ Onboarding: Character saved to backend successfully');

      // Only store in SharedPreferences AFTER backend confirms success
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_character_id', selectedCharacter['id']);
      await prefs.setString(
          'selected_character_gender', selectedCharacter['gender']);
      await prefs.setInt(
          'selected_character_number', selectedCharacter['number']);
      print('✅ Onboarding: Character cached to SharedPreferences');

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select character: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336), // Error color
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _selectCharacter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildFeaturesPage(),
                    _buildCharacterSelectionPage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 102),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5CACEE),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5CACEE),
                              ),
                            )
                          : Text(
                              _currentPage == 2 ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 25),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(
              Icons.favorite,
              size: 80,
              color: Color(0xFF5CACEE),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 204),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Welcome to Your\nWellness Journey',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF5CACEE).withValues(alpha: 38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5CACEE)),
            ),
            child: const Text(
              'Track your mood, journal your thoughts,\nand grow with your character',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Key Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFeatureCard(
                    Icons.mood,
                    'Track Your Mood',
                    'Log your emotions and see patterns over time',
                    const Color(0xFFFFD54F), // Yellow
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.book,
                    'Journal Daily',
                    'Write your thoughts and reflections',
                    const Color(0xFF5CACEE), // Blue
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.star,
                    'Earn Rewards',
                    'Complete tasks and unlock achievements',
                    const Color(0xFF66BB6A), // Green
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.psychology,
                    'Character Companion',
                    'Watch your companion grow and change with you',
                    const Color(0xFFFFA726), // Orange
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 127)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 204),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A4B80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated Character Selection Page without flutter_gif
  Widget _buildCharacterSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Choose Your Character',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A4B80).withValues(alpha: 25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF0A4B80).withValues(alpha: 76)),
            ),
            child: const Text(
              'Your character will grow and change with you',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0A4B80),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _characterOptions.length,
              itemBuilder: (context, index) {
                final character = _characterOptions[index];
                final isSelected = _selectedCharacterId == character['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCharacterId = character['id'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? character['color']
                            : Colors.grey.withValues(alpha: 76),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? (character['color'] as Color)
                                  .withValues(alpha: 76)
                              : Colors.black.withValues(alpha: 13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Character GIF - using standard Image.asset
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: character['color'], width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.asset(
                              character['gifPath'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          character['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: character['color'],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            character['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0A4B80),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: character['color'],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
