import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allAchievements = [];
  List<dynamic> _userAchievements = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      // Try cache first
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'achievements_data',
        maxAge: CacheService.mediumCache,
      );

      if (cachedData != null && mounted) {
        setState(() {
          _userData = cachedData['user'];
          _allAchievements = cachedData['all'] ?? [];
          _userAchievements = cachedData['user_achievements'] ?? [];
          _isLoading = false;
        });
      }

      // Fetch fresh data
      final user = await _apiService.getCurrentUser();
      final allAchievements = await _apiService.getAllAchievements();
      final userAchievements = await _apiService.getUserAchievements();

      // Cache fresh data
      await CacheService().set('achievements_data', {
        'user': user,
        'all': allAchievements,
        'user_achievements': userAchievements,
      });

      if (mounted) {
        setState(() {
          _userData = user;
          _allAchievements = allAchievements;
          _userAchievements = userAchievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading achievements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isUnlocked(int achievementId) {
    return _userAchievements.any((ua) => ua['achievement_id'] == achievementId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SkeletonLoader.card(height: 120),
            const SizedBox(height: 24),
            SkeletonLoader.grid(
              itemCount: 6,
              crossAxisCount: 2,
              childAspectRatio: 0.85,
            ),
          ],
        ),
      );
    }

    final unlockedCount = _userAchievements.length;
    final totalCount = _allAchievements.length;
    final xp = _userData?['xp'] ?? 0;
    final level = _userData?['level'] ?? 1;

    return RefreshIndicator(
      onRefresh: _loadAchievements,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(unlockedCount, totalCount, xp, level),
            const SizedBox(height: 24),
            const Text(
              'All Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
            ),
            const SizedBox(height: 16),
            if (_allAchievements.isEmpty)
              _buildEmptyState()
            else
              _buildAchievementsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int unlocked, int total, int xp, int level) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked / $total Unlocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Level', '$level'),
              _buildStat('Total XP', '$xp'),
              _buildStat(
                  'Completion', '${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _allAchievements[index];
        final isUnlocked = _isUnlocked(achievement['id']);
        return _buildAchievementCard(achievement, isUnlocked);
      },
    );
  }

  Widget _buildAchievementCard(
      Map<String, dynamic> achievement, bool isUnlocked) {
    final category = achievement['category'] as String;
    final color = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? [color, color.withValues(alpha: 0.7)]
                          : [Colors.grey[400]!, Colors.grey[300]!],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  achievement['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isUnlocked ? const Color(0xFF0A4B80) : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${achievement['xp_reward']} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            ),
          if (isUnlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Achievements Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete activities to unlock achievements!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mood':
        return AppColors.info;
      case 'journal':
        return AppColors.success;
      case 'todo':
        return AppColors.warning;
      case 'social':
        return AppColors.secondary;
      case 'streak':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mood':
        return Icons.mood;
      case 'journal':
        return Icons.book;
      case 'todo':
        return Icons.check_circle;
      case 'social':
        return Icons.people;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.emoji_events;
    }
  }
}
