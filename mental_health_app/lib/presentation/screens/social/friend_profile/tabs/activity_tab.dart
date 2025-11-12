import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ActivityTab extends StatelessWidget {
  final List<dynamic> friendTodos;
  final List<dynamic> friendMoodLogs;
  final Map<String, dynamic>? friendCharacterState;
  final String friendName;

  const ActivityTab({
    super.key,
    required this.friendTodos,
    required this.friendMoodLogs,
    required this.friendCharacterState,
    required this.friendName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood Section
          _buildMoodSection(),
          const SizedBox(height: 20),

          // All Todos (scrollable)
          _buildAllTodosSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    final moodScore = friendCharacterState?['mood_score']?.toDouble() ?? 50.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mood,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '7-Day Mood Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A4B80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mood Score Bar
          Row(
            children: [
              const Text(
                'Mood Score:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: moodScore / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              moodScore > 70
                                  ? Colors.green
                                  : moodScore > 40
                                      ? Colors.orange
                                      : Colors.red,
                              moodScore > 70
                                  ? Colors.lightGreen
                                  : moodScore > 40
                                      ? Colors.deepOrange
                                      : Colors.redAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${moodScore.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: moodScore > 70
                      ? Colors.green
                      : moodScore > 40
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-Day Chart
          _buildMoodChart(),

          const SizedBox(height: 16),

          // Recent Moods List
          if (friendMoodLogs.isNotEmpty) _buildRecentMoodsList(),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    if (friendMoodLogs.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No mood data available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    // Group mood logs by day (last 7 days)
    final now = DateTime.now();
    final last7Days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final moodHeights = <double>[];
    final moodColors = <Color>[];
    final dayLabels = <String>[];

    for (var day in last7Days) {
      dayLabels.add(
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1]);

      // Find mood log for this day
      final dayLog = friendMoodLogs.firstWhere(
        (log) {
          final logDate = DateTime.parse(log['logged_at']);
          return logDate.year == day.year &&
              logDate.month == day.month &&
              logDate.day == day.day;
        },
        orElse: () => null,
      );

      if (dayLog != null) {
        final mood = dayLog['mood'] as String;
        final moodScores = {
          'happy': 100.0,
          'calm': 80.0,
          'tired': 50.0,
          'anxious': 30.0,
          'sad': 20.0,
          'angry': 10.0,
        };
        final moodColorMap = {
          'happy': const Color(0xFFFFD700),
          'calm': const Color(0xFF4ECDC4),
          'tired': const Color(0xFF95A5A6),
          'anxious': const Color(0xFFFFA500),
          'sad': const Color(0xFF9575CD),
          'angry': const Color(0xFFE74C3C),
        };
        moodHeights.add(moodScores[mood] ?? 50.0);
        moodColors.add(moodColorMap[mood] ?? Colors.grey);
      } else {
        moodHeights.add(0.0);
        moodColors.add(Colors.grey[300]!);
      }
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final height = moodHeights[index];
          final hasData = height > 0;

          return Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasData)
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: moodColors[index],
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: hasData ? (height * 0.5) : 10,
                  decoration: BoxDecoration(
                    color: moodColors[index],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 9,
                    color: hasData ? Colors.black87 : Colors.grey,
                    fontWeight: hasData ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecentMoodsList() {
    // Take last 5 moods
    final recentMoods = friendMoodLogs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Moods',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A4B80),
          ),
        ),
        const SizedBox(height: 12),
        ...recentMoods.map((log) {
          final mood = log['mood'] as String;
          final loggedAt = DateTime.parse(log['logged_at']);
          final moodEmoji = _getMoodEmoji(mood);
          final moodColor = _getMoodColor(mood);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: moodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: moodColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  moodEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mood.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: moodColor,
                    ),
                  ),
                ),
                Text(
                  '${loggedAt.day}/${loggedAt.month}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return const Color(0xFFFFD700);
      case 'calm':
      case 'content':
        return const Color(0xFF4ECDC4);
      case 'tired':
        return const Color(0xFF95A5A6);
      case 'anxious':
      case 'struggling':
        return const Color(0xFFFFA500);
      case 'sad':
        return const Color(0xFF9575CD);
      case 'angry':
      case 'needs_support':
        return const Color(0xFFE74C3C);
      default:
        return AppColors.primary;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'thriving':
        return '😊';
      case 'calm':
      case 'content':
        return '😌';
      case 'tired':
        return '😴';
      case 'anxious':
      case 'struggling':
        return '😰';
      case 'sad':
        return '😢';
      case 'angry':
      case 'needs_support':
        return '😠';
      default:
        return '😐';
    }
  }

  Widget _buildAllTodosSection() {
    final completedCount =
        friendTodos.where((t) => t['is_completed'] == true).length;
    final totalCount = friendTodos.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.checklist,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$friendName\'s All Goals',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A4B80),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (friendTodos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No goals set for today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Display ALL todos (not limited to 3)
            ...friendTodos.map((todo) => _buildTodoItem(todo)).toList(),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final isCompleted = todo['is_completed'] ?? false;
    final title = todo['task_text'] ?? todo['title'] ?? 'Untitled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCompleted ? AppColors.success.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.grey : const Color(0xFF0A4B80),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
