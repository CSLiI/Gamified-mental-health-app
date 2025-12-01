import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QuestCard extends StatelessWidget {
  final String task;
  final String category;
  final String difficulty;
  final int xpReward;
  final int progressCurrent;
  final int progressTotal;
  final bool isCompleted;
  final String questType; // daily or weekly
  final DateTime? expiresAt;

  const QuestCard({
    Key? key,
    required this.task,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.progressCurrent,
    required this.progressTotal,
    required this.isCompleted,
    required this.questType,
    this.expiresAt,
  }) : super(key: key);

  Color get _difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String get _categoryEmoji {
    switch (category.toLowerCase()) {
      case 'mood':
        return '😊';
      case 'journal':
        return '📝';
      case 'social':
        return '👥';
      case 'streak':
        return '🔥';
      case 'general':
        return '✓';
      default:
        return '📋';
    }
  }

  String get _timeRemaining {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);

    if (difference.isNegative) return 'Expired';

    if (difference.inHours > 24) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return '${difference.inMinutes}m left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = progressTotal > 0 ? progressCurrent / progressTotal : 0.0;
    final isExpired = expiresAt != null &&
        expiresAt!.isBefore(DateTime.now()) &&
        !isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Progress background
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                color: isCompleted
                    ? AppColors.success
                    : isExpired
                        ? Colors.grey
                        : _difficultyColor,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _categoryEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.grey
                                    : AppColors.textPrimary,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildBadge(
                                  difficulty.toUpperCase(),
                                  _difficultyColor,
                                  isOutlined: true,
                                ),
                                const SizedBox(width: 8),
                                _buildBadge(
                                  '+$xpReward XP',
                                  AppColors.warning,
                                  icon: Icons.stars,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 28,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isCompleted
                                ? 'Completed!'
                                : isExpired
                                    ? 'Expired'
                                    : 'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? AppColors.success
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '$progressCurrent/$progressTotal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? AppColors.success
                                : isExpired
                                    ? Colors.grey
                                    : _difficultyColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Footer
                  if (!isCompleted &&
                      !isExpired &&
                      _timeRemaining.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeRemaining,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color,
      {bool isOutlined = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
