import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _apiService = ApiService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _characterState;
  Map<String, dynamic>? _currentCharacter;
  bool _isLoading = true;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Setup blink animation for effect
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.white,
              backgroundColor: const Color(0xFF89CFF0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildCharacterCard(),
                          const SizedBox(height: 24),
                          _buildDailyQuests(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    final level = _userData?['level'] ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF89CFF0).withAlpha(180),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha(50),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gamified level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5CACEE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'LVL $level',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Coin counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gameYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_userData?['coins'] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = _userData?['first_name'] ?? 'Hero';
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
            fontFamily: 'Roboto',
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Gamified name display
        Text(
          firstName,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Dialogue box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF89CFF0),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Color(0xFF5CACEE)),
              SizedBox(width: 8),
              Text(
                'How is your adventure today?',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Color(0xFF0078D7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    final characterState = _characterState?['character_state'] ?? 'content';
    final moodScore = _characterState?['mood_score'] ?? 50.0;
    final characterName =
        _currentCharacter?['character']?['name'] ?? 'Your Companion';

    // Get XP and Level
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final xpForNextLevel = level * 100;
    final xpProgress = xp / xpForNextLevel;

    // Determine card style based on character state
    Color stateColor;
    String stateEmoji;

    switch (characterState) {
      case 'thriving':
        stateColor = AppColors.gameGreen;
        stateEmoji = '🌟';
        break;
      case 'struggling':
        stateColor = AppColors.gameYellow;
        stateEmoji = '💪';
        break;
      case 'needs_support':
        stateColor = AppColors.gamePink;
        stateEmoji = '🤗';
        break;
      default:
        stateColor = AppColors.gameBlue;
        stateEmoji = '😊';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: stateColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character sprite
              AnimatedBuilder(
                animation: _blinkController,
                builder: (context, child) {
                  final glowOpacity = 0.3 +
                      (_blinkController.value * 0.3); // Ranges from 0.3 to 0.6

                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: stateColor,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color:
                              stateColor.withAlpha((glowOpacity * 255).round()),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 60,
                          color: stateColor,
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: stateColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stateEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      characterName,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0078D7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withAlpha(51), // ~20% opacity
                        border: Border.all(
                          color: stateColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stateEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getGamefiedState(characterState),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CACEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5CACEE).withAlpha(76),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Level $level  •  $xp XP',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCharacterMessage(characterState),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: stateColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Energy',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0078D7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${moodScore.toStringAsFixed(0)}/100',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Energy bar
              Stack(
                children: [
                  // Background
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withAlpha(128),
                        width: 1,
                      ),
                    ),
                  ),
                  // Progress
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      // Calculate the width based on mood score
                      final barWidth = MediaQuery.of(context).size.width *
                          0.8 *
                          moodScore /
                          100;

                      // Get slightly darker color for low health
                      final barColor = moodScore < 30 ? Colors.red : stateColor;

                      return Container(
                        height: 16,
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                  // Segmentation lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      10,
                      (index) => Container(
                        width: 1,
                        height: 16,
                        color: Colors.black.withAlpha(26),
                        margin: EdgeInsets.only(
                          left: index == 0
                              ? 0
                              : MediaQuery.of(context).size.width * 0.068,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Color(0xFF5CACEE),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'XP Progress',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0078D7),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(xpProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5CACEE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // XP bar
                  Stack(
                    children: [
                      // Background
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withAlpha(128),
                            width: 1,
                          ),
                        ),
                      ),
                      // Progress
                      AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          final barWidth = MediaQuery.of(context).size.width *
                              0.8 *
                              xpProgress;

                          return Container(
                            height: 16,
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5CACEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                      // Segmentation lines
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          10,
                          (index) => Container(
                            width: 1,
                            height: 16,
                            color: Colors.black.withAlpha(26),
                            margin: EdgeInsets.only(
                              left: index == 0
                                  ? 0
                                  : MediaQuery.of(context).size.width * 0.068,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${xpForNextLevel - xp} XP to level ${level + 1}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_upward,
                        size: 12,
                        color: Color(0xFF5CACEE),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Quest header - using book icon instead of Pokemon ball
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                border: Border.all(
                  color: const Color(0xFF5CACEE),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.menu_book, // Quest book icon
                    color: Color(0xFF5CACEE),
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'DAILY QUESTS',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0078D7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gameGreen.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gameGreen,
                  width: 2,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_box,
                    size: 14,
                    color: AppColors.gameGreen,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '2/3',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gameGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuestItem(
          title: 'Log your mood',
          description: 'Record how you feel today',
          iconData: Icons.mood,
          color: AppColors.gameYellow,
          rewardXP: 10,
          isCompleted: true,
        ),
        const SizedBox(height: 10),
        _buildQuestItem(
          title: 'Write in journal',
          description: 'Share your thoughts today',
          iconData: Icons.book,
          color: AppColors.gameBlue,
          rewardXP: 15,
          isCompleted: true,
        ),
        const SizedBox(height: 10),
        _buildQuestItem(
          title: 'Complete 3 tasks',
          description: 'Check off items from your list',
          iconData: Icons.checklist,
          color: const Color(0xFF5CACEE),
          rewardXP: 20,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildQuestItem({
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required int rewardXP,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted ? color : Colors.grey.withAlpha(76),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: isCompleted ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF0078D7) : Colors.grey,
                    decoration: isCompleted
                        ? TextDecoration.none
                        : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: isCompleted
                        ? Colors.black54
                        : Colors.grey.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCompleted
                    ? color.withAlpha(178)
                    : Colors.grey.withAlpha(76),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '+$rewardXP',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            border: Border.all(
              color: const Color(0xFF5CACEE),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Color(0xFF5CACEE),
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0078D7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _buildActionCard(
              icon: Icons.mood,
              label: 'Log Mood',
              color: AppColors.gameYellow,
              index: 1,
            ),
            _buildActionCard(
              icon: Icons.book,
              label: 'Journal',
              color: AppColors.gameBlue,
              index: 2,
            ),
            _buildActionCard(
              icon: Icons.checklist,
              label: 'Tasks',
              color: const Color(0xFF5CACEE),
              index: 3,
            ),
            _buildActionCard(
              icon: Icons.emoji_events,
              label: 'Achievements',
              color: AppColors.gameGreen,
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
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(index);
        }
        // Add haptic feedback
        HapticFeedback.mediumImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!(index);
              }
              HapticFeedback.mediumImpact();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Item icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(76),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  // Button label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGamefiedState(String state) {
    switch (state) {
      case 'thriving':
        return "ENERGIZED";
      case 'content':
        return "BALANCED";
      case 'struggling':
        return "PERSISTING";
      case 'needs_support':
        return "RESTING";
      default:
        return "READY";
    }
  }

  String _getCharacterMessage(String state) {
    switch (state) {
      case 'thriving':
        return "Your companion is in peak condition! Keep it up! ✨";
      case 'content':
        return "Your journey progresses well, brave adventurer! 🌱";
      case 'struggling':
        return "Your companion is hanging in there. Don't give up! 💪";
      case 'needs_support':
        return "Time to recharge and restore your energy! 🤗";
      default:
        return "I'm your faithful companion on this quest! 🌟";
    }
  }
}
