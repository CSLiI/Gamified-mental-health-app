import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/dio_client.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/utils/image_cache_manager.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/providers/pet_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _dioClient = DioClient();
  final Debouncer _actionDebouncer = Debouncer(milliseconds: 350);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic>? _userData;
  List<dynamic> _achievements = [];
  Map<String, dynamic>? _moodState;
  Map<String, dynamic>? _levelProgress; // Store level progress data
  List<dynamic> _equippedRewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get user ID for user-specific storage
      final userIdStr =
          await _secureStorage.read(key: StorageKeys.currentUserId);
      final userId = userIdStr != null ? int.tryParse(userIdStr) : null;

      // Load built-in equipped rewards from secure storage (USER-SPECIFIC)
      final builtinEquippedJson = userId != null
          ? await _secureStorage.read(
              key: StorageKeys.builtinEquippedRewards(userId))
          : null;
      final builtinEquipped = builtinEquippedJson != null
          ? (jsonDecode(builtinEquippedJson) as List)
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      // Check cache first
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'profile_data',
        maxAge: CacheService.shortCache,
      );

      if (cachedData != null && mounted) {
        setState(() {
          _userData = cachedData['user'];
          _achievements = cachedData['achievements'] ?? [];
          _moodState = cachedData['moodState'];
          _levelProgress = cachedData['levelProgress']; // Load from cache
          // Merge backend equipped with built-in equipped
          _equippedRewards = [
            ...(cachedData['equippedRewards'] ?? []),
            ...builtinEquipped,
          ];
          _isLoading = false;
        });
      }

      // Fetch fresh data in background using Future.wait
      // Call getLevelProgress first to sync level in DB
      final levelProgress = await _apiService.getLevelProgress();

      // Force check achievements to ensure stats are up to date
      try {
        await _apiService.checkAchievements();
      } catch (e) {
        print('Error checking achievements: $e');
      }

      final results = await Future.wait([
        _apiService.getFreshUserData(), // Get fresh user data with synced level
        _apiService.getMyAchievements(),
        _apiService.getEquippedRewards(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final achievements = results[1] as List<dynamic>;
      final equippedRewards = results[2] as List<dynamic>;

      // Get character mood state if user has a character
      Map<String, dynamic>? moodState;
      if (user['character'] != null) {
        try {
          moodState = await _apiService.getCharacterMoodState();
        } catch (e) {
          print('Error loading mood state: $e');
        }
      }

      // Update cache
      await CacheService().set('profile_data', {
        'user': user,
        'achievements': achievements,
        'moodState': moodState,
        'levelProgress': levelProgress,
        'equippedRewards': equippedRewards,
      });

      if (mounted) {
        // Load built-in equipped rewards again (in case changed) (USER-SPECIFIC)
        final builtinEquippedJson = userId != null
            ? await _secureStorage.read(
                key: StorageKeys.builtinEquippedRewards(userId))
            : null;
        final builtinEquipped = builtinEquippedJson != null
            ? (jsonDecode(builtinEquippedJson) as List)
                .cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        setState(() {
          _userData = user;
          _achievements = achievements;
          _moodState = moodState;
          _levelProgress = levelProgress; // Store level progress
          // Merge backend equipped with built-in equipped
          _equippedRewards = [
            ...equippedRewards,
            ...builtinEquipped,
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _actionDebouncer.run(() async {
        await _dioClient.logout();
        // Clear ALL providers on logout to prevent data leakage
        if (mounted) {
          await context.read<ThemeProvider>().clearTheme();
          await context.read<MoodProvider>().clearMood();
          await context.read<CharacterProvider>().clearCharacter();
          await context.read<UserProvider>().clearUser();
          context.read<PetProvider>().clear();
        }
        if (!mounted) return;
        context.go('/login');
      });
    }
  }

  // Helper methods for equipped rewards
  Map<String, dynamic>? _getEquippedRewardByCategory(String category) {
    try {
      return _equippedRewards.firstWhere(
        (reward) {
          final rewardData = reward['reward'] ?? reward;
          return (rewardData['category'] ?? '').toString().toLowerCase() ==
              category.toLowerCase();
        },
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  Color _getThemeColor1() {
    final theme = _getEquippedRewardByCategory('themes');
    if (theme != null) {
      final rewardData = theme['reward'] ?? theme;
      final colorValue = rewardData['color1'];
      if (colorValue is int) return Color(colorValue);
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _getThemeColor2() {
    final theme = _getEquippedRewardByCategory('themes');
    if (theme != null) {
      final rewardData = theme['reward'] ?? theme;
      final colorValue = rewardData['color2'];
      if (colorValue is int) return Color(colorValue);
    }
    return Theme.of(context).colorScheme.secondary;
  }

  Color? _getFrameColor() {
    final frame = _getEquippedRewardByCategory('frames');
    if (frame != null) {
      final rewardData = frame['reward'] ?? frame;
      final colorValue = rewardData['accent'];
      if (colorValue is int) return Color(colorValue);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeProvider.primaryColor.withValues(alpha: 0.08),
                  themeProvider.secondaryColor.withValues(alpha: 0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: _isLoading
                  ? _buildProfileSkeleton()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            _buildStatsSection(),
                            if (_equippedRewards.isNotEmpty)
                              _buildEquippedSection(),
                            _buildOptionsSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header skeleton
          SkeletonLoader.character(size: 120),
          const SizedBox(height: 16),
          SkeletonLoader.text(width: 150, height: 20),
          const SizedBox(height: 8),
          SkeletonLoader.text(width: 200, height: 14),
          const SizedBox(height: 24),
          // Stats skeleton
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader.card(height: 80)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader.card(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          // Options skeleton
          SkeletonLoader.card(height: 60),
          const SizedBox(height: 12),
          SkeletonLoader.card(height: 60),
          const SizedBox(height: 12),
          SkeletonLoader.card(height: 60),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _userData?['first_name'] ?? 'User';
    final lastName = _userData?['last_name'] ?? '';
    final email = _userData?['email'] ?? '';
    // Use levelProgress for accurate level/XP, fallback to userData
    final level = _levelProgress?['level'] ?? _userData?['level'] ?? 1;
    final xp = _levelProgress?['total_xp'] ?? _userData?['xp'] ?? 0;
    final xpInCurrentLevel =
        _levelProgress?['xp_in_current_level'] ?? (xp % 100);
    final xpForNextLevel = _levelProgress?['xp_for_next_level'] ?? 100;
    final character = _userData?['character'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Equipped banner decoration

            // Character Avatar with mood-based glow
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getThemeColor1().withOpacity(0.15),
                        _getThemeColor2().withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _getFrameColor() ??
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: _getFrameColor() != null ? 4 : 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: character != null
                        ? _buildCharacterImage(character)
                        : Icon(
                            Icons.person_rounded,
                            size: 55,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                ),
                // Level badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD93D), Color(0xFFFFB347)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD93D).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        'Lv.$level',
                        style: const TextStyle(
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
            const SizedBox(height: 16),
            Text(
              '$firstName $lastName',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            // Show equipped profile badge if any
            if (_getEquippedRewardByCategory('profile') != null) ...[
              const SizedBox(height: 8),
              _buildEquippedBadge(),
            ],
            const SizedBox(height: 20),
            // XP Progress bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.08),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Experience',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$xpInCurrentLevel / $xpForNextLevel XP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (xpInCurrentLevel / xpForNextLevel)
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final currentStreak = _userData?['current_streak'] ?? 0;
    // Use levelProgress for accurate level, fallback to userData
    final level = _levelProgress?['level'] ?? _userData?['level'] ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Cards in a Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: currentStreak.toString(),
                  label: 'Day Streak',
                  color: const Color(0xFFFF6B6B),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE5E5), Color(0xFFFFF0F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  value: _achievements.length.toString(),
                  label: 'Achievements',
                  color: const Color(0xFFFFB347),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF8E5), Color(0xFFFFFBF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mood State Card
          if (_moodState != null) _buildMoodStateCard(),
        ],
      ),
    );
  }

  Widget _buildMoodStateCard() {
    final characterState = _moodState?['character_state'] ?? 'content';
    final moodScore = (_moodState?['mood_score'] ?? 50).toDouble();

    // Map character state to display info
    String stateLabel;
    Color stateColor;
    IconData stateIcon;

    switch (characterState) {
      case 'thriving':
        stateLabel = 'Thriving';
        stateColor = AppColors.stateThriving;
        stateIcon = Icons.sentiment_very_satisfied_rounded;
        break;
      case 'content':
        stateLabel = 'Content';
        stateColor = AppColors.stateContent;
        stateIcon = Icons.sentiment_satisfied_rounded;
        break;
      case 'struggling':
        stateLabel = 'Keep Going';
        stateColor = AppColors.stateStruggling;
        stateIcon = Icons.sentiment_neutral_rounded;
        break;
      case 'needs_support':
        stateLabel = 'You\'re Not Alone';
        stateColor = AppColors.stateNeedsSupport;
        stateIcon = Icons.favorite_rounded;
        break;
      default:
        stateLabel = 'Content';
        stateColor = AppColors.stateContent;
        stateIcon = Icons.sentiment_satisfied_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stateColor.withOpacity(0.15),
            stateColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stateColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(stateIcon, color: stateColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wellness Status',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stateLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: stateColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${moodScore.toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stateColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    Gradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Theme.of(context).cardColor : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Equipped Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_equippedRewards.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equippedRewards.map((equippedReward) {
                final rewardData = equippedReward['reward'] ?? equippedReward;
                final name = rewardData['name'] ?? 'Reward';
                final category = rewardData['category'] ?? 'item';
                return _buildEquippedItemChip(name, category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquippedItemChip(String name, String category) {
    final color = _getCategoryColorForChip(category);
    final icon = _getCategoryIconForChip(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColorForChip(String category) {
    switch (category.toLowerCase()) {
      case 'themes':
        return const Color(0xFF4FC3F7);
      case 'banners':
        return const Color(0xFFFF8A65);
      case 'frames':
        return const Color(0xFF9C27B0);
      case 'profile':
        return const Color(0xFF66BB6A);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIconForChip(String category) {
    switch (category.toLowerCase()) {
      case 'themes':
        return Icons.palette_rounded;
      case 'banners':
        return Icons.flag_rounded;
      case 'frames':
        return Icons.crop_square_rounded;
      case 'profile':
        return Icons.badge_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Widget _buildOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.tune_rounded,
            title: 'Preferences',
            subtitle: 'Customize your experience',
            color: AppColors.primary,
            onTap: () {
              // Navigate to settings
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage reminders',
            color: AppColors.secondary,
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Get assistance',
            color: AppColors.info,
            onTap: () {
              // Navigate to help
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'App version and info',
            color: AppColors.gameGreen,
            onTap: () {
              // Show about dialog
            },
          ),
          const SizedBox(height: 24),
          // Logout Button - Standalone design
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.3), width: 1.5),
            ),
            child: Material(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _logout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerDecoration() {
    final bannerReward = _getEquippedRewardByCategory('banners');
    if (bannerReward == null) return const SizedBox.shrink();

    final rewardData = bannerReward['reward'] ?? bannerReward;
    final color1Value = rewardData['color1'];
    final color2Value = rewardData['color2'];
    final color1 = color1Value is int ? Color(color1Value) : AppColors.primary;
    final color2 =
        color2Value is int ? Color(color2Value) : AppColors.secondary;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 16,
            child: Icon(Icons.auto_awesome,
                color: Colors.white.withOpacity(0.5), size: 20),
          ),
          Center(
            child: Text(
              (rewardData['name'] ?? '').toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Icon(Icons.star_rounded,
                color: Colors.white.withOpacity(0.5), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedBadge() {
    final profileReward = _getEquippedRewardByCategory('profile');
    if (profileReward == null) return const SizedBox.shrink();

    final rewardData = profileReward['reward'] ?? profileReward;
    final name = rewardData['name'] ?? 'Badge';
    final accentValue = rewardData['accent'];
    final accentColor =
        accentValue is int ? Color(accentValue) : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: accentColor, size: 16),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage(Map<String, dynamic> character) {
    final gender = character['gender'] ?? 'boy';
    final characterNumber = character['number'] ?? 1;

    // Get mood state from character mood state
    String moodState = 'Calm'; // Default to Calm (was neutral)
    if (_moodState != null && _moodState!['character_state'] != null) {
      // Map character_state to mood state for GIF filename (proper case)
      switch (_moodState!['character_state']) {
        case 'thriving':
          moodState = 'Happy';
          break;
        case 'content':
          moodState = 'Calm';
          break;
        case 'struggling':
          moodState = 'Sad';
          break;
        case 'needs_support':
          moodState = 'Angry';
          break;
        default:
          moodState = 'Calm';
      }
    }

    final genderPrefix = gender == 'female' ? 'Girl' : 'Boy';

    // Format: HappyBoy1.gif
    return ImageCacheManager().buildCachedImage(
      assetPath:
          'assets/images/${genderPrefix}_Gif_33FPS/$moodState$genderPrefix$characterNumber.gif',
      fit: BoxFit.cover,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _actionDebouncer.run(() async => onTap()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: tileColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
