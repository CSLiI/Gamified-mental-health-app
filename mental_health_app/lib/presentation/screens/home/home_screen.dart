import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
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
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    final characterState = _characterState?['character_state'] ?? 'content';
    final moodScore = _characterState?['mood_score'] ?? 50.0;
    final environment = _characterState?['environment'] ?? 'peaceful';
    final characterName = _currentCharacter?['character']?['name'] ?? 'Your Companion';

    // Get XP and Level
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final xpForNextLevel = level * 100;
    final xpProgress = xp / xpForNextLevel;

    Color stateColor;
    String stateEmoji;
    Color environmentColor;

    switch (characterState) {
      case 'thriving':
        stateColor = AppColors.stateThriving;
        stateEmoji = '🌟';
        environmentColor = AppColors.envVibrant;
        break;
      case 'struggling':
        stateColor = AppColors.stateStruggling;
        stateEmoji = '💪';
        environmentColor = AppColors.envCloudy;
        break;
      case 'needs_support':
        stateColor = AppColors.stateNeedsSupport;
        stateEmoji = '🤗';
        environmentColor = AppColors.envStormy;
        break;
      default:
        stateColor = AppColors.stateContent;
        stateEmoji = '😊';
        environmentColor = AppColors.envPeaceful;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            environmentColor.withOpacity(0.15),
            stateColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: stateColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character Avatar Placeholder (Human silhouette)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      stateColor.withOpacity(0.3),
                      stateColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stateColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 60,
                      color: stateColor,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          stateEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      characterName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
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
                            characterState.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Level and XP Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Level $level  •  $xp XP',
                            style: const TextStyle(
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
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
          // Mood Score Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mood Score',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${moodScore.toStringAsFixed(0)}/100',
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
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'XP Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(xpProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${xpForNextLevel - xp} XP to level ${level + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
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
              color: AppColors.moodHappy,
              gradient: [AppColors.moodHappy.withOpacity(0.8), AppColors.moodHappy],
            ),
            _buildActionCard(
              icon: Icons.book,
              label: 'Journal',
              color: AppColors.primary,
              gradient: [AppColors.primary.withOpacity(0.8), AppColors.primary],
            ),
            _buildActionCard(
              icon: Icons.checklist,
              label: 'Tasks',
              color: AppColors.secondary,
              gradient: [AppColors.secondary.withOpacity(0.8), AppColors.secondary],
            ),
            _buildActionCard(
              icon: Icons.emoji_events,
              label: 'Achievements',
              color: AppColors.moodCalm,
              gradient: [AppColors.moodCalm.withOpacity(0.8), AppColors.moodCalm],
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
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate based on label
            if (widget.onNavigate != null) {
              switch (label) {
                case 'Log Mood':
                  widget.onNavigate!(1);
                  break;
                case 'Journal':
                  widget.onNavigate!(2);
                  break;
                case 'Tasks':
                  widget.onNavigate!(3);
                  break;
                case 'Achievements':
                  widget.onNavigate!(4);
                  break;
              }
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
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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