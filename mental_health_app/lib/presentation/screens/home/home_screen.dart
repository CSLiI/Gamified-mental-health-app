import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../mood/mood_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _characterState;
  Map<String, dynamic>? _currentCharacter;
  bool _isLoading = true;

  // Character details from shared preferences
  int _characterId = 1;
  String _characterGender = 'Boy';
  int _characterNumber = 1;
  bool _characterDetailsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCharacterDetails();
    _loadData();
  }

  void _updateCharacterMood(String mood) {
    setState(() {
      // Update the character state based on the selected mood
      _characterState?['character_state'] = mood; // Update the character state
    });
  }

  Future<void> _loadCharacterDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _characterId = prefs.getInt('selected_character_id') ?? 1;
        _characterGender =
            prefs.getString('selected_character_gender') ?? 'Boy';
        _characterNumber = prefs.getInt('selected_character_number') ?? 1;
        _characterDetailsLoaded = true;
      });
    } catch (e) {
      print('Error loading character details: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await _apiService.getCurrentUser();

      Map<String, dynamic>? characterState;
      Map<String, dynamic>? currentCharacter;

      try {
        characterState = await _apiService.getCharacterMoodState();
      } catch (e) {
        print('Character state error: $e');
      }

      try {
        currentCharacter = await _apiService.getCurrentCharacter();
      } catch (e) {
        print('Current character error: $e');
      }

      setState(() {
        _userData = user;
        _characterState = characterState;
        _currentCharacter = currentCharacter;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Get the appropriate character GIF path based on mood state
  String _getCharacterGifPath(String moodState) {
    // Default to "calm" mood if not recognized
    String mood = 'Calm';

    switch (moodState) {
      case 'thriving':
        mood = 'Happy';
        break;
      case 'content':
        mood = 'Calm';
        break;
      case 'struggling':
        mood = 'Tired';
        break;
      case 'needs_support':
        mood = 'Sad';
        break;
    }

    // Construct path based on character gender, number and mood
    return 'assets/images/${_characterGender}_Gif_33FPS/$mood$_characterGender$_characterNumber.gif';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFFFFF), // Pure white at top
            Color(0xFFF5FAFF), // Very light blue-white
            Color(0xFFEBF5FF), // Soft pastel blue-white
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF5CACEE),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildCharacterCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = _userData?['first_name'] ?? 'User';
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: const TextStyle(
            fontSize: 20,
            color: AppColors
                .textPrimary, // Dark text for contrast with white background
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors
                .textPrimary, // Dark text for contrast with white background
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary, // Slightly lighter dark text
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    final characterState = _characterState?['character_state'] ?? 'content';
    final moodScore = _characterState?['mood_score'] ?? 50.0;
    final firstName = _userData?['first_name'] ?? 'User';

    // Get XP and Level
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final xpForNextLevel = level * 100;
    final double xpProgress = xpForNextLevel > 0 ? (xp / xpForNextLevel) : 0.0;

    Color stateColor;

    switch (characterState) {
      case 'thriving':
        stateColor = const Color(0xFF4CAF50); // Green
        break;
      case 'struggling':
        stateColor = const Color(0xFFFFA726); // Orange
        break;
      case 'needs_support':
        stateColor = const Color(0xFFF44336); // Red
        break;
      default:
        stateColor = const Color(0xFF5CACEE); // Baby blue
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Use a more visible pastel surface color
        color: AppColors.background
            .withValues(alpha: 0.6), // Medium sky blue with transparency
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stateColor.withValues(alpha: 0.8), width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character GIF Display (removed overlay chip)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                clipBehavior: Clip.hardEdge,
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: _characterDetailsLoaded
                      ? Image.asset(
                          _getCharacterGifPath(characterState),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.person,
                                  size: 50, color: Colors.grey),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username (next to character, above Level)
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 18, color: Color(0xFF0A4B80)),
                        const SizedBox(width: 6),
                        Text(
                          firstName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A4B80), // not white
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Level Display (fully centered in the pill)
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CACEE).withValues(alpha: 51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: high-contrast star badge (and reserved width)
                          SizedBox(
                            width: 32,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: stateColor, // solid background
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.star,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                          // Center: text truly centered
                          Expanded(
                            child: Center(
                              child: Text(
                                'Level $level',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A4B80),
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          // Right: mirror the left space to keep symmetry
                          const SizedBox(width: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // XP Display
                    Text(
                      '$xp / $xpForNextLevel XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // XP Progress Bar with high contrast
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: xpProgress.clamp(0.0, 1.0).toDouble(),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0A4B80),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mood Score Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getMoodIcon(characterState),
                        size: 18,
                        color: stateColor,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: _getFormattedState(characterState),
                        child: Text(
                          'Mood: $characterState',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A4B80),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${moodScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: moodScore / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Character message
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCharacterMessage(characterState),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String state) {
    switch (state) {
      case 'thriving':
        return Icons.sentiment_very_satisfied;
      case 'content':
        return Icons.sentiment_satisfied;
      case 'struggling':
        return Icons.sentiment_neutral;
      case 'needs_support':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  String _getFormattedState(String state) {
    final words = state.split('_');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getCharacterMessage(String state) {
    switch (state) {
      case 'thriving':
        return "You're doing amazing! Keep up the great work! ✨";
      case 'content':
        return "Life is good. You're on the right path! 🌱";
      case 'struggling':
        return "Hang in there. Take it one step at a time. 💪";
      case 'needs_support':
        return "Remember, it's okay to ask for help. You're not alone. 🤗";
      default:
        return "I'm here with you on this journey. 🌟";
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.bolt,
              size: 24,
              color: AppColors
                  .textPrimary, // Dark icon for contrast with white background
            ),
            SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors
                    .textPrimary, // Dark text for contrast with white background
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              icon: Icons.mood,
              label: 'Log Mood',
              color: AppColors.info, // Blue from AppColors
              borderColor: AppColors.info, // Blue outline
              index: 1,
            ),
            _buildActionCard(
              icon: Icons.book,
              label: 'Journal',
              color: AppColors.success, // Green from AppColors
              borderColor: AppColors.success, // Green outline
              index: 2,
            ),
            _buildActionCard(
              icon: Icons.checklist,
              label: 'Tasks',
              color: AppColors.warning, // Orange from AppColors
              borderColor: AppColors.warning, // Orange outline
              index: 3,
            ),
            _buildActionCard(
              icon: Icons.emoji_events,
              label: 'Achievements',
              color: AppColors.error, // Red from AppColors
              borderColor: AppColors.error, // Red outline
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
    required Color borderColor,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        // Use a more visible pastel version of the card's theme color
        color: color.withValues(
            alpha: 0.25), // 25% opacity for more visible pastel effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 3), // Thicker outline
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (label == 'Log Mood') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodScreen(
                    characterId: _characterId, // Pass the characterId
                    characterGender: _characterGender,
                    characterNumber:
                        _characterNumber, // Pass the characterNumber
                    onMoodSelected: (mood) {
                      _updateCharacterMood(mood); // Update mood in HomeScreen
                    },
                  ),
                ),
              );
            } else if (widget.onNavigate != null) {
              widget.onNavigate!(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color, // Solid color for icon background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon,
                      color: Colors.white, size: 32), // White icon color
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: borderColor, // Text color matches outline
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
