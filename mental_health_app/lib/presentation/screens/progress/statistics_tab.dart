import 'package:flutter/material.dart';
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

class _StatisticsTabState extends State<StatisticsTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _moodLogs = [];
  List<dynamic> _journalEntries = [];
  List<dynamic> _todos = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  int _totalXP = 0;

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
      final user = await _apiService.getCurrentUser();
      final moods = await _apiService.getMoodLogs();
      final journals = await _apiService.getJournalEntries();
      final todos = await _apiService.getTodos();

      // Cache the fresh data
      await CacheService().set('statistics_data', {
        'streak': user['streak'] ?? 0,
        'xp': user['xp'] ?? 0,
        'moods': moods,
        'journals': journals,
        'todos': todos,
      });

      if (mounted) {
        setState(() {
          _currentStreak = user['streak'] ?? 0;
          _totalXP = user['xp'] ?? 0;
          _moodLogs = moods;
          _journalEntries = journals;
          _todos = todos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: SkeletonLoader.card(height: 100)),
                const SizedBox(width: 16),
                Expanded(child: SkeletonLoader.card(height: 100)),
              ],
            ),
            const SizedBox(height: 24),
            SkeletonLoader.card(height: 250),
            const SizedBox(height: 24),
            SkeletonLoader.card(height: 200),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            const Text(
              'Mood Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
            ),
            const SizedBox(height: 16),
            _buildMoodChart(),
            const SizedBox(height: 24),
            const Text(
              'Activity Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
            ),
            const SizedBox(height: 16),
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
        const SizedBox(width: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
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
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: distribution.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_capitalizeFirstLetter(entry.key)} (${entry.value})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0A4B80),
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
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: Icons.auto_stories,
          title: 'Journal Entries',
          count: _journalEntries.length,
          subtitle: 'Total entries',
          color: const Color(0xFF9C27B0),
        ),
        const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
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
                    color: Color(0xFF0A4B80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFD700);
      case 'excited':
        return const Color(0xFFFF6B6B);
      case 'calm':
        return const Color(0xFF4ECDC4);
      case 'anxious':
        return const Color(0xFFFFA500);
      case 'sad':
        return const Color(0xFF95A5A6);
      case 'angry':
        return const Color(0xFFE74C3C);
      case 'neutral':
        return const Color(0xFFBDC3C7);
      default:
        return AppColors.primary;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
