import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

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

  // Store the last selected mood temporarily
  String? _lastSelectedMood;

  @override
  void initState() {
    super.initState();
    _loadCharacterDetails();
    _loadLastSelectedMood(); // Load persisted mood
    _loadData();
  }

  Future<void> _loadLastSelectedMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMood = prefs.getString('last_selected_mood');
      if (savedMood != null) {
        setState(() {
          _lastSelectedMood = savedMood;
        });
        print('📱 Loaded persisted mood: $savedMood');
      }
    } catch (e) {
      print('Error loading last mood: $e');
    }
  }

  void _updateCharacterMood(String mood) async {
    print('🎭 HOME SCREEN: Updating character mood to: $mood');

    // Map mood to character state
    String characterState;
    switch (mood.toLowerCase()) {
      case 'happy':
        characterState = 'thriving';
        break;
      case 'calm':
        characterState = 'content';
        break;
      case 'tired':
      case 'anxious':
        characterState = 'struggling';
        break;
      case 'sad':
      case 'angry':
        characterState = 'needs_support';
        break;
      default:
        characterState = 'content';
    }

    print('📊 Mapped $mood → $characterState');

    // Save to SharedPreferences for persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mood', mood);
      print('💾 Saved mood to SharedPreferences: $mood');
    } catch (e) {
      print('Error saving mood: $e');
    }

    setState(() {
      // Store the selected mood
      _lastSelectedMood = mood;

      // Update the character state
      if (_characterState == null) {
        _characterState = {};
      }
      _characterState!['character_state'] = characterState;
    });

    print('✅ HOME SCREEN: Character state updated to: $characterState');
    print('📝 _lastSelectedMood is now: $_lastSelectedMood');
  }

  Future<void> _loadCharacterDetails() async {
    try {
      // Fetch character from backend API instead of local storage
      final currentCharacter = await _apiService.getCurrentCharacter();

      if (currentCharacter['character'] != null) {
        final character = currentCharacter['character'];
        setState(() {
          _characterId = character['id'] ?? 1;
          _characterGender = character['gender'] ?? 'Boy';
          _characterNumber = character['number'] ?? 1;
          _characterDetailsLoaded = true;
        });

        // Update SharedPreferences to match (for offline access)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selected_character_id', _characterId);
        await prefs.setString('selected_character_gender', _characterGender);
        await prefs.setInt('selected_character_number', _characterNumber);
      }
    } catch (e) {
      print('Error loading character details: $e');
      // Fallback to SharedPreferences if API fails
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
        print('Error loading from SharedPreferences: $e');
      }
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
  String _getCharacterGifPath(String mood) {
    // Capitalize the mood for the GIF filename
    String capitalizedMood;

    switch (mood.toLowerCase()) {
      case 'happy':
        capitalizedMood = 'Happy';
        break;
      case 'calm':
        capitalizedMood = 'Calm';
        break;
      case 'tired':
        capitalizedMood = 'Tired';
        break;
      case 'anxious':
        capitalizedMood = 'Anxious';
        break;
      case 'sad':
        capitalizedMood = 'Sad';
        break;
      case 'angry':
        capitalizedMood = 'Angry';
        break;
      // Handle backend states (fallback)
      case 'thriving':
        capitalizedMood = 'Happy';
        break;
      case 'content':
        capitalizedMood = 'Calm';
        break;
      case 'struggling':
        capitalizedMood = 'Tired';
        break;
      case 'needs_support':
        capitalizedMood = 'Sad';
        break;
      default:
        capitalizedMood = 'Calm';
    }

    // Construct path based on character gender, number and mood
    return 'assets/images/${_characterGender}_Gif_33FPS/$capitalizedMood$_characterGender$_characterNumber.gif';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5CACEE)),
              ),
            )
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
                    _buildSocialButton(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                  ],
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
            color: Color(
                0xFF0A4B80), // Dark blue for consistency with other screens
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(
                0xFF0A4B80), // Dark blue for consistency with other screens
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: Color(
                0xFF0A4B80), // Dark blue for consistency with other screens
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    print('🎨 Building character card...');
    print('   _lastSelectedMood: $_lastSelectedMood');

    // Use the last selected mood if available, otherwise use backend data
    String displayMood;
    Color moodColor;

    if (_lastSelectedMood != null) {
      print(
          '   Using last selected mood: "$_lastSelectedMood" (length: ${_lastSelectedMood!.length})');
      print('   Mood bytes: ${_lastSelectedMood!.codeUnits}');
      displayMood = _lastSelectedMood!;

      // Map mood to its specific color
      switch (_lastSelectedMood!.toLowerCase()) {
        case 'happy':
          moodColor = const Color(0xFFFFD54F); // Yellow
          break;
        case 'calm':
          moodColor = const Color(0xFF42A5F5); // Blue
          break;
        case 'tired':
          moodColor = const Color(0xFF78909C); // Blue Grey
          break;
        case 'anxious':
          moodColor = const Color(0xFFFFA726); // Orange
          break;
        case 'sad':
          moodColor = const Color(0xFF9575CD); // Purple
          break;
        case 'angry':
          moodColor = const Color(0xFFEF5350); // Red
          break;
        default:
          moodColor = const Color(0xFF42A5F5); // Default blue
      }
    } else {
      print('   Using backend data');
      // Use backend data with state colors
      final characterState = _characterState?['character_state'] ?? 'content';
      displayMood = characterState;

      switch (characterState) {
        case 'thriving':
          moodColor = AppColors.stateThriving;
          break;
        case 'struggling':
          moodColor = AppColors.stateStruggling;
          break;
        case 'needs_support':
          moodColor = AppColors.stateNeedsSupport;
          break;
        default:
          moodColor = AppColors.gameBlue;
      }
    }

    print('   Final displayMood: $displayMood, color: $moodColor');

    final moodScore = _characterState?['mood_score'] ?? 50.0;
    final firstName = _userData?['first_name'] ?? 'User';

    // Get XP and Level
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final xpForNextLevel = level * 100;
    final double xpProgress = xpForNextLevel > 0 ? (xp / xpForNextLevel) : 0.0;

    // Use moodColor from above (already set based on mood/state)
    final Color stateColor = moodColor;

    // Compute a contrasting text color against the mood-tinted background
    final Color contrastTextColor = stateColor.computeLuminance() > 0.5
        ? AppColors.textPrimary
        : Colors.white;

    // Brighter versions of state color for card background
    final Color brighterStateColor =
        Color.lerp(stateColor, Colors.white, 0.5) ?? stateColor;
    final Color lightestStateColor =
        Color.lerp(stateColor, Colors.white, 0.7) ?? stateColor;

    // Slightly darker but still vibrant for level display text contrast
    final Color darkerStateColor =
        Color.lerp(stateColor, Colors.black, 0.15) ?? stateColor;

    // Very light background for progress bars (lighter than card)
    final Color progressBarBackground =
        Color.lerp(stateColor, Colors.white, 0.7) ?? stateColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightestStateColor.withValues(alpha: 0.9),
            brighterStateColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: stateColor.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 1,
          ),
        ],
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
                          _getCharacterGifPath(displayMood),
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
                        color: stateColor.withValues(alpha: 0.35),
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: darkerStateColor,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: contrastTextColor,
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
                        backgroundColor:
                            progressBarBackground.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stateColor,
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
                        _getMoodIcon(displayMood),
                        size: 18,
                        color: darkerStateColor,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: _getFormattedState(displayMood),
                        child: Text(
                          'Mood: ${displayMood.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: contrastTextColor,
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
                      color: contrastTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: moodScore / 100,
                  backgroundColor: progressBarBackground.withValues(alpha: 0.5),
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
                  _getCharacterMessage(displayMood),
                  style: TextStyle(
                    fontSize: 13,
                    color: contrastTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return Icons.sentiment_very_satisfied;
      case 'calm':
      case 'content':
        return Icons.sentiment_satisfied;
      case 'tired':
      case 'anxious':
      case 'struggling':
        return Icons.sentiment_neutral;
      case 'sad':
      case 'angry':
      case 'needs_support':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  String _getFormattedState(String mood) {
    final words = mood.split('_');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getCharacterMessage(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return "You're doing amazing! Keep up the great work! ✨";
      case 'calm':
      case 'content':
        return "Life is good. You're on the right path! 🌱";
      case 'tired':
      case 'anxious':
      case 'struggling':
        return "Hang in there. Take it one step at a time. 💪";
      case 'sad':
      case 'angry':
      case 'needs_support':
        return "Remember, it's okay to ask for help. You're not alone. 🤗";
      default:
        return "I'm here with you on this journey. 🌟";
    }
  }

  Widget _buildSocialButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to social screen
        context.go('/social');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF667EEA), // Purple
              Color(0xFF764BA2), // Darker purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.people,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🤝 Connect with Friends',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your journey & stay accountable',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
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
              color: Color(
                  0xFF0A4B80), // Dark blue for consistency with other screens
            ),
            SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(
                    0xFF0A4B80), // Dark blue for consistency with other screens
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
    // Darker version of the color for better contrast
    final Color darkerColor = Color.lerp(color, Colors.black, 0.15) ?? color;

    return Container(
      decoration: BoxDecoration(
        // Gradient background with the action card color
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (label == 'Log Mood') {
              // Use the bottom navigation to switch to Mood tab instead of Navigator.push
              if (widget.onNavigate != null) {
                widget.onNavigate!(1); // Switch to Mood tab (index 1)
              }
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
                    color: darkerColor, // Darker color for icon background
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
                    color: darkerColor, // Darker text for better contrast
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
