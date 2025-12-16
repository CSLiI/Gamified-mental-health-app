import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            SkeletonLoader.card(height: 180.h),
            SizedBox(height: 24.h),
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(unlockedCount, totalCount, xp, level),
            SizedBox(height: 24.h),
            _buildCategoryFilter(),
            SizedBox(height: 20.h),
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA), // Solid color
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
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
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.15 + (_pulseController.value * 0.1)),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber
                              .withOpacity(0.3 * _pulseController.value),
                          blurRadius: 20.r,
                          spreadRadius: 5.r,
                        ),
                      ],
                    ),
                    child: Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 48.sp),
                  );
                },
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Hunter',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$unlocked / $total',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('Unlocked',
                        style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(7.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 14.h,
                width: (MediaQuery.of(context).size.width - 88.w) * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.amber, Color(0xFFFFD54F)]),
                  borderRadius: BorderRadius.circular(7.r),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.amber.withOpacity(0.5), blurRadius: 8.r)
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Stats row
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.trending_up_rounded, 'Level', '$level'),
                Container(width: 1.w, height: 40.h, color: Colors.white24),
                _buildStatItem(Icons.star_rounded, 'XP', '$xp'),
                Container(width: 1.w, height: 40.h, color: Colors.white24),
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
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 4.h),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.white60, fontSize: 11.sp)),
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
            padding: EdgeInsets.only(right: 10.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: 1.5.w),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h))
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'],
                        size: 18.sp,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600),
                    SizedBox(width: 6.w),
                    Text(
                      cat['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13.sp,
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
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
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isUnlocked ? 15.r : 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
          border: isUnlocked
              ? Border.all(color: color.withOpacity(0.3), width: 2.w)
              : null,
        ),
        child: Stack(
          children: [
            // Decorative circle
            if (isUnlocked)
              Positioned(
                top: -15.h,
                right: -15.w,
                child: Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color.withOpacity(0.1)),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  SizedBox(height: 8.h),
                  // Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: isUnlocked ? color : Colors.grey.shade400, // Solid color
                          shape: BoxShape.circle,
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 4.h))
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: _buildIcon(achievement['icon_url'], category, 64.w),
                      ),
                      if (!isUnlocked)
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: Icon(Icons.lock_rounded,
                              color: Colors.white, size: 28.sp),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    achievement['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? const Color(0xFF2D3436)
                          : Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    achievement['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  // XP chip
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.amber.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14.sp,
                            color: isUnlocked ? Colors.amber : Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          '+$xpReward XP',
                          style: TextStyle(
                            fontSize: 12.sp,
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
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 8.r)
                    ],
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 14.sp),
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
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r))),
            SizedBox(height: 24.h),
            Container(
              width: 100.w,
              height: 100.w,
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
                      blurRadius: 20.r,
                      offset: Offset(0, 8.h))
                ],
              ),
              alignment: Alignment.center,
              child: _buildIcon(achievement['icon_url'], category, 100.w),
            ),
            SizedBox(height: 20.h),
            Text(achievement['name'],
                style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436))),
            SizedBox(height: 8.h),
            Text(achievement['description'],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDetailChip(
                    icon: Icons.category_rounded,
                    label: _formatCategory(category),
                    color: color),
                SizedBox(width: 12.w),
                _buildDetailChip(
                    icon: Icons.star_rounded,
                    label: '+${achievement['xp_reward']} XP',
                    color: Colors.amber),
              ],
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isUnlocked ? Icons.check_circle : Icons.lock_outline,
                      color: isUnlocked ? AppColors.success : Colors.grey),
                  SizedBox(width: 8.w),
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
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_outlined,
                  size: 50.sp, color: Colors.grey.shade400),
            ),
            SizedBox(height: 20.h),
            Text('No Achievements Here',
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            SizedBox(height: 8.h),
            Text('Try selecting a different category!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500)),
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
