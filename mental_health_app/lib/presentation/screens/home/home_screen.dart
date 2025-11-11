import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../../data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _characterState;
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

      try {
        characterState = await _apiService.getCharacterMoodState();
      } catch (e) {
        print('Character state error: $e');
      }

      if (mounted) {
        setState(() {
          _userData = user;
          _characterState = characterState;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCharacterGifPath(String mood, String gender, int number) {
    String moodState;
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        moodState = 'Happy';
        break;
      case 'calm':
      case 'content':
        moodState = 'Calm';
        break;
      case 'tired':
      case 'anxious':
      case 'struggling':
        moodState = 'Anxious';
        break;
      case 'sad':
        moodState = 'Sad';
        break;
      case 'angry':
      case 'needs_support':
        moodState = 'Angry';
        break;
      default:
        moodState = 'Calm';
    }
    return 'assets/images/${gender}_Gif_33FPS/$moodState$gender$number.gif';
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
              onRefresh: () async {
                await _loadData();
                if (mounted) {
                  await context.read<MoodProvider>().loadMood();
                }
              },
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
    );
  }

  Widget _buildHeader() {
    final firstName = _userData?['first_name'] ?? 'User';
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF0A4B80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4B80),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => context.go('/notifications'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF0A4B80),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    return Consumer2<MoodProvider, CharacterProvider>(
      builder: (context, moodProvider, characterProvider, child) {
        final mood = moodProvider.currentMood;
        final moodColor = moodProvider.getMoodColor();

        final moodScore = _characterState?['mood_score'] ?? 50.0;
        final firstName = _userData?['first_name'] ?? 'User';
        final level = _userData?['level'] ?? 1;
        final xp = _userData?['xp'] ?? 0;
        final xpForNextLevel = level * 100;
        final double xpProgress =
            xpForNextLevel > 0 ? (xp / xpForNextLevel) : 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(moodColor, Colors.white, 0.7)!
                    .withValues(alpha: 0.9),
                Color.lerp(moodColor, Colors.white, 0.5)!
                    .withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: moodColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: Image.asset(
                        _getCharacterGifPath(
                          mood ?? 'calm',
                          characterProvider.characterGender,
                          characterProvider.characterNumber,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.person,
                                size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                color: Color(0xFF0A4B80),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            color: moodColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: moodColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.star,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Level $level',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color.lerp(
                                          moodColor, Colors.black, 0.15),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$xp / $xpForNextLevel XP',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0A4B80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: xpProgress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                Color.lerp(moodColor, Colors.white, 0.7)!
                                    .withValues(alpha: 0.5),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(moodColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mood, size: 18, color: moodColor),
                          const SizedBox(width: 8),
                          Text(
                            'Mood: ${mood ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A4B80),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${moodScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4B80),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: moodScore / 100,
                      backgroundColor: Color.lerp(moodColor, Colors.white, 0.7)!
                          .withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt, size: 24, color: Color(0xFF0A4B80)),
            SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
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
              color: AppColors.info,
              index: 1,
            ),
            _buildActionCard(
              icon: Icons.book,
              label: 'Journal',
              color: AppColors.success,
              index: 2,
            ),
            _buildActionCard(
              icon: Icons.checklist,
              label: 'Quests',
              color: AppColors.warning,
              index: 3,
            ),
            _buildActionCard(
              icon: Icons.emoji_events,
              label: 'Achievements',
              color: AppColors.error,
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
    final Color darkerColor = Color.lerp(color, Colors.black, 0.15) ?? color;

    return Container(
      decoration: BoxDecoration(
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
            // Map labels to new navbar indices
            // New navbar: [Home=0, Social=1, Progress=2, Mood=3, Profile=4]
            if (label == 'Log Mood') {
              widget.onNavigate?.call(3); // Mood tab
            } else if (label == 'Journal') {
              context.go('/journal'); // Navigate to journal route
            } else if (label == 'Quests') {
              context.go('/todos'); // Navigate to todos route
            } else if (label == 'Achievements') {
              widget.onNavigate?.call(2); // Progress tab
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
                    color: darkerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkerColor,
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
