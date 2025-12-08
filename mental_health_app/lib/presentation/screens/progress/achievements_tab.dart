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

class _AchievementsTabState extends State<AchievementsTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _allAchievements = [];
  List<dynamic> _userAchievements = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _selectedCategory = 'all';
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'label': 'All',
      'icon': Icons.grid_view_rounded,
      'color': const Color(0xFF667EEA)
    },
    {
      'id': 'mood',
      'label': 'Mood',
      'icon': Icons.mood_rounded,
      'color': const Color(0xFF74B9FF)
    },
    {
      'id': 'journal',
      'label': 'Journal',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xFF00B894)
    },
    {
      'id': 'todo',
      'label': 'Tasks',
      'icon': Icons.task_alt_rounded,
      'color': const Color(0xFFFDCB6E)
    },
    {
      'id': 'social',
      'label': 'Social',
      'icon': Icons.people_rounded,
      'color': const Color(0xFFA29BFE)
    },
    {
      'id': 'streak',
      'label': 'Streak',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFFF7675)
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadAchievements();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
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

      final results = await Future.wait([
        _apiService.getCurrentUser(),
        _apiService.getAllAchievements(),
        _apiService.getUserAchievements(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final allAchievements = results[1] as List<dynamic>;
      final userAchievements = results[2] as List<dynamic>;

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isUnlocked(int achievementId) {
    return _userAchievements.any((ua) => ua['achievement_id'] == achievementId);
  }

  List<dynamic> get _filteredAchievements {
    if (_selectedCategory == 'all') return _allAchievements;
    return _allAchievements.where((a) {
      final category = (a['category'] as String).toLowerCase();
      
      // Handle special mapping for streak/consistency
      if (_selectedCategory == 'streak') {
        return category.contains('consistency') || category.contains('streak');
      }
      
      return category.contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SkeletonLoader.card(height: 180),
            const SizedBox(height: 24),
            SkeletonLoader.grid(
                itemCount: 6, crossAxisCount: 2, childAspectRatio: 0.85),
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
      color: const Color(0xFF667EEA),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(unlockedCount, totalCount, xp, level),
            const SizedBox(height: 24),
            _buildCategoryFilter(),
            const SizedBox(height: 20),
            if (_filteredAchievements.isEmpty)
              _buildEmptyState()
            else
              _buildAchievementsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(int unlocked, int total, int xp, int level) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA), // Solid color
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated trophy container
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.15 + (_pulseController.value * 0.1)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber
                              .withOpacity(0.3 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 48),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievement Hunter',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlocked / $total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('Unlocked',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 14,
                width: (MediaQuery.of(context).size.width - 88) * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.amber, Color(0xFFFFD54F)]),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.amber.withOpacity(0.5), blurRadius: 8)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.trending_up_rounded, 'Level', '$level'),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem(Icons.star_rounded, 'XP', '$xp'),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem(Icons.percent_rounded, 'Done',
                    '${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          final color = cat['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: 1.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'],
                        size: 18,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _filteredAchievements[index];
        final isUnlocked = _isUnlocked(achievement['id']);
        return _buildAchievementCard(achievement, isUnlocked);
      },
    );
  }

  Widget _buildAchievementCard(
      Map<String, dynamic> achievement, bool isUnlocked) {
    final category = achievement['category'] as String;
    final color = _getCategoryColor(category);
    final xpReward = achievement['xp_reward'] ?? 0;

    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement, isUnlocked),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isUnlocked ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isUnlocked
              ? Border.all(color: color.withOpacity(0.3), width: 2)
              : null,
        ),
        child: Stack(
          children: [
            // Decorative circle
            if (isUnlocked)
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color.withOpacity(0.1)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  const SizedBox(height: 8),
                  // Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isUnlocked ? color : Colors.grey.shade400, // Solid color
                          shape: BoxShape.circle,
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: _buildIcon(achievement['icon_url'], category, 64),
                      ),
                      if (!isUnlocked)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 28),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    achievement['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? const Color(0xFF2D3436)
                          : Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // XP chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.amber.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14,
                            color: isUnlocked ? Colors.amber : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpReward XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.amber[700] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),

            // Unlocked check
            if (isUnlocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(
      Map<String, dynamic> achievement, bool isUnlocked) {
    final category = achievement['category'] as String;
    final color = _getCategoryColor(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [color, color.withOpacity(0.7)]
                      : [Colors.grey.shade400, Colors.grey.shade300],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color:
                          (isUnlocked ? color : Colors.grey).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              alignment: Alignment.center,
              child: _buildIcon(achievement['icon_url'], category, 100),
            ),
            const SizedBox(height: 20),
            Text(achievement['name'],
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436))),
            const SizedBox(height: 8),
            Text(achievement['description'],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDetailChip(
                    icon: Icons.category_rounded,
                    label: _formatCategory(category),
                    color: color),
                const SizedBox(width: 12),
                _buildDetailChip(
                    icon: Icons.star_rounded,
                    label: '+${achievement['xp_reward']} XP',
                    color: Colors.amber),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isUnlocked ? Icons.check_circle : Icons.lock_outline,
                      color: isUnlocked ? AppColors.success : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked
                        ? 'Achievement Unlocked!'
                        : 'Keep going to unlock!',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? AppColors.success : Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_outlined,
                  size: 50, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('No Achievements Here',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Try selecting a different category!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('mood')) return const Color(0xFF74B9FF);
    if (cat.contains('journal')) return const Color(0xFF00B894);
    if (cat.contains('todo') || cat.contains('task'))
      return const Color(0xFFFDCB6E);
    if (cat.contains('social')) return const Color(0xFFA29BFE);
    if (cat.contains('streak') || cat.contains('consistency'))
      return const Color(0xFFFF7675);
    return const Color(0xFF667EEA);
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('mood')) return Icons.mood_rounded;
    if (cat.contains('journal')) return Icons.auto_stories_rounded;
    if (cat.contains('todo') || cat.contains('task'))
      return Icons.task_alt_rounded;
    if (cat.contains('social')) return Icons.people_rounded;
    if (cat.contains('streak') || cat.contains('consistency'))
      return Icons.local_fire_department_rounded;
    return Icons.emoji_events_rounded;
  }

  Widget _buildIcon(String? iconUrl, String category, double size) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      // Remove leading slash if present to match asset path
      final assetPath =
          iconUrl.startsWith('/') ? iconUrl.substring(1) : iconUrl;
      
      // Debug print
      // print('Loading icon: $assetPath');

      return ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading icon: $assetPath - $error');
            return Icon(_getCategoryIcon(category),
                color: Colors.white, size: size * 0.6);
          },
        ),
      );
    }
    return Icon(_getCategoryIcon(category), color: Colors.white, size: size);
  }
}
