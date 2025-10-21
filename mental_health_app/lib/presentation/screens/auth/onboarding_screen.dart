import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _apiService = ApiService();
  final _pageController = PageController();
  int _currentPage = 0;
  List<dynamic> _characters = [];
  int? _selectedCharacterId;
  bool _isLoading = false;

  late AnimationController _blinkController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _loadCharacters();

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blinkController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    try {
      final characters = await _apiService.getCharacters();
      setState(() {
        _characters = characters;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to find companions: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectCharacter() async {
    if (_selectedCharacterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must choose a companion for your journey!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.chooseCharacter(_selectedCharacterId!);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to bond with companion: ${e.toString()}'),
          backgroundColor: AppColors.error,
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      HapticFeedback.mediumImpact();
    } else {
      _selectCharacter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CACEE),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withAlpha(70),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withAlpha(100),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gamified button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5CACEE),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF5CACEE),
                              ),
                            )
                          : Text(
                              _currentPage == 2
                                  ? 'START YOUR JOURNEY'
                                  : 'CONTINUE',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
          // Animated glowing logo
          AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              final glowOpacity = 0.4 +
                  (_blinkController.value * 0.4); // Ranges from 0.4 to 0.8

              return Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(70),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.white.withAlpha((glowOpacity * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.psychology,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Title card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  'WELCOME TO YOUR',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'MENTAL HEALTH ADVENTURE',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Track your moods, complete quests,\nand evolve with your companion',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gameYellow.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'GAMIFIED MENTAL WELLNESS',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'KEY FEATURES',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildFeatureCard(
                    Icons.mood,
                    'Mood Tracking',
                    'Monitor your emotions and see patterns over time',
                    AppColors.gameYellow,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.book,
                    'Daily Journal',
                    'Record your thoughts and reflections',
                    AppColors.gameBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.checklist,
                    'Task Manager',
                    'Organize to-do lists and track your progress',
                    Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.emoji_events,
                    'Achievements',
                    'Complete goals and earn rewards',
                    AppColors.gameGreen,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(100),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: const Text(
              'CHOOSE YOUR COMPANION',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your companion will evolve as you progress',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _characters.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _characters.length,
                    itemBuilder: (context, index) {
                      final character = _characters[index];
                      final isSelected =
                          _selectedCharacterId == character['id'];

                      // Character colors
                      final List<Color> characterColors = [
                        AppColors.gameYellow,
                        AppColors.gameBlue,
                        Colors.white,
                        AppColors.gameGreen,
                      ];
                      final characterColor =
                          characterColors[index % characterColors.length];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCharacterId = character['id'];
                          });
                          HapticFeedback.mediumImpact();
                        },
                        child: AnimatedBuilder(
                          animation: _blinkController,
                          builder: (context, child) {
                            final glowOpacity = isSelected
                                ? (0.4 + (_blinkController.value * 0.4))
                                : 0.1;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected
                                      ? characterColor
                                      : Colors.white,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? Colors.white.withAlpha(
                                            (glowOpacity * 255).round())
                                        : Colors.black.withAlpha(30),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Character icon with rotation for selected
                                  AnimatedBuilder(
                                    animation: _rotateController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: isSelected
                                            ? _rotateController.value *
                                                2 *
                                                math.pi
                                            : 0,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(100),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.pets,
                                            size: 36,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Character name box
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(100),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      character['name'] ?? 'Companion',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      character['description'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'SELECTED',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5CACEE),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
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
