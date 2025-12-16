import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _moodLogs = [];
  List<dynamic> _journalEntries = [];
  List<dynamic> _todos = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  int _totalXP = 0;
  String _timeRange = 'week'; // 'week', 'month', 'all'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Try cache first for instant loading
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'statistics_data',
        maxAge: CacheService.mediumCache,
      );

      if (cachedData != null && mounted) {
        setState(() {
          _currentStreak = cachedData['streak'] ?? 0;
          _totalXP = cachedData['xp'] ?? 0;
          _moodLogs = cachedData['moods'] ?? [];
          _journalEntries = cachedData['journals'] ?? [];
          _todos = cachedData['todos'] ?? [];
          _isLoading = false;
        });
      }

      // Fetch fresh data in background
      // print('📊 Loading statistics...');

      final results = await Future.wait([
        _apiService.getCurrentUser(),
        _apiService.getMoodLogs(),
        _apiService.getJournalEntries(),
        _apiService.getTodos(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      // print('✅ User data loaded: ${user.toString()}');

      final moods = results[1] as List<dynamic>;
      // print('✅ Mood logs loaded: ${moods.length} entries');

      final journals = results[2] as List<dynamic>;
      // print('✅ Journal entries loaded: ${journals.length} entries');

      final todos = results[3] as List<dynamic>;
      // print('✅ Todos loaded: ${todos.length} entries');

      // Filter moods by time range
      final now = DateTime.now();
      List<dynamic> filteredMoods = moods;
      if (_timeRange != 'all') {
        final daysAgo = _timeRange == 'week' ? 7 : 30;
        final cutoffDate = now.subtract(Duration(days: daysAgo));

        filteredMoods = moods.where((mood) {
          final loggedAt = DateTime.parse(mood['logged_at']);
          return loggedAt.isAfter(cutoffDate);
        }).toList();
      }

      // Cache the fresh data
      await CacheService().set('statistics_data', {
        'streak': user['current_streak'] ?? 0,
        'xp': user['xp'] ?? 0,
        'moods': filteredMoods,
        'journals': journals,
        'todos': todos,
      });

      if (mounted) {
        setState(() {
          _currentStreak = user['current_streak'] ?? 0;
          _totalXP = user['xp'] ?? 0;
          _moodLogs = filteredMoods;
          _journalEntries = journals;
          _todos = todos;
          _isLoading = false;
        });

        // print('📈 Statistics updated:');
        // print('  - Streak: $_currentStreak');
        // print('  - XP: $_totalXP');
        // print('  - Mood logs: ${_moodLogs.length}');
        // print('  - Journals: ${_journalEntries.length}');
        // print('  - Todos: ${_todos.length}');
      }
    } catch (e) {
      // print('❌ Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load statistics: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Map<String, int> _getMoodDistribution() {
    final distribution = <String, int>{};
    for (var log in _moodLogs) {
      final mood = log['mood'] as String;
      distribution[mood] = (distribution[mood] ?? 0) + 1;
    }
    return distribution;
  }

  int _getCompletedTodos() {
    return _todos.where((todo) => todo['is_completed'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: SkeletonLoader.card(height: 100.h)),
                SizedBox(width: 16.w),
                Expanded(child: SkeletonLoader.card(height: 100.h)),
              ],
            ),
            SizedBox(height: 24.h),
            SkeletonLoader.card(height: 250.h),
            SizedBox(height: 24.h),
            SkeletonLoader.card(height: 200.h),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            SizedBox(height: 24.h),
            Text(
              'Mood Distribution',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A4B80),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border:
                    Border.all(color: const Color(0xFF0A4B80).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _timeRange,
                  isExpanded: true,
                  isDense: false,
                  menuMaxHeight: 250.h,
                  alignment: AlignmentDirectional.centerStart,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A4B80)),
                  icon: Icon(Icons.arrow_drop_down,
                      color: const Color(0xFF0A4B80), size: 24.sp),
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                    DropdownMenuItem(value: 'all', child: Text('All Time')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _timeRange = value!;
                      _isLoading = true;
                    });
                    _loadStatistics();
                  },
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _buildMoodChart(),
            SizedBox(height: 24.h),
            Text(
              'Activity Summary',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A4B80),
              ),
            ),
            SizedBox(height: 16.h),
            _buildActivitySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            title: 'Streak',
            value: '$_currentStreak',
            subtitle: 'days',
            color: AppColors.error,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            title: 'Total XP',
            value: '$_totalXP',
            subtitle: 'points',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color, // Solid color
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    final distribution = _getMoodDistribution();

    if (distribution.isEmpty) {
      return _buildEmptyState(
        'No mood data yet',
        'Start logging your moods to see trends',
      );
    }

    final total = distribution.values.reduce((a, b) => a + b);
    final sections = distribution.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        color: _getMoodColor(entry.key),
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 80.r,
        titleStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40.r,
                startDegreeOffset: -90,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: distribution.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${_capitalizeFirstLetter(entry.key)} (${entry.value})',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF0A4B80),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary() {
    final completedTodos = _getCompletedTodos();
    final totalTodos = _todos.length;
    final completionRate =
        totalTodos > 0 ? (completedTodos / totalTodos * 100).round() : 0;

    return Column(
      children: [
        _buildActivityCard(
          icon: Icons.mood,
          title: 'Mood Logs',
          count: _moodLogs.length,
          subtitle: 'Total entries',
          color: AppColors.primary,
        ),
        SizedBox(height: 12.h),
        _buildActivityCard(
          icon: Icons.auto_stories,
          title: 'Journal Entries',
          count: _journalEntries.length,
          subtitle: 'Total entries',
          color: const Color(0xFF9C27B0),
        ),
        SizedBox(height: 12.h),
        _buildActivityCard(
          icon: Icons.check_circle,
          title: 'Todos Completed',
          count: completedTodos,
          subtitle: '$completionRate% completion rate',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required int count,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 32.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A4B80),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 60.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFD54F); // Yellow - matches mood page
      case 'calm':
        return const Color(0xFF42A5F5); // Blue - matches mood page
      case 'tired':
        return const Color(0xFF78909C); // Blue Grey - matches mood page
      case 'anxious':
        return const Color(0xFFFFA726); // Orange - matches mood page
      case 'sad':
        return const Color(0xFF9575CD); // Purple - matches mood page
      case 'angry':
        return const Color(0xFFEF5350); // Red - matches mood page
      default:
        return AppColors.primary;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
