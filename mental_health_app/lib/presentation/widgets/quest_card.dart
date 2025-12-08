import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QuestCard extends StatelessWidget {
  final int? questId;
  final String task;
  final String category;
  final String difficulty;
  final int xpReward;
  final int progressCurrent;
  final int progressTotal;
  final bool isCompleted;
  final String questType; // daily or weekly
  final DateTime? expiresAt;
  final VoidCallback? onManualComplete;
  final Function(int)? onIncrementProgress;
  final bool rewardClaimed;

  const QuestCard({
    Key? key,
    this.questId,
    required this.task,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.progressCurrent,
    required this.progressTotal,
    required this.isCompleted,
    required this.questType,
    this.expiresAt,
    this.onManualComplete,
    this.onIncrementProgress,
    this.rewardClaimed = false,
  }) : super(key: key);

  Color _getDifficultyColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return theme.primaryColor;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  int _getEnergyReward() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 5;
      case 'medium':
        return 10;
      case 'hard':
        return 15;
      default:
        return 5;
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

  /// Check if this quest requires manual completion (external activities)
  bool get _requiresManualAction {
    final lowerTask = task.toLowerCase();
    return lowerTask.contains('walk') ||
        lowerTask.contains('workout') ||
        lowerTask.contains('exercise') ||
        lowerTask.contains('read') ||
        lowerTask.contains('meditat') ||
        lowerTask.contains('water') ||
        lowerTask.contains('sleep') ||
        lowerTask.contains('breathing') ||
        lowerTask.contains('social media') ||
        lowerTask.contains('call') ||
        lowerTask.contains('meet') ||
        lowerTask.contains('draw') ||
        lowerTask.contains('doodle') ||
        lowerTask.contains('create') ||
        lowerTask.contains('self-care') ||
        lowerTask.contains('learn') ||
        lowerTask.contains('grateful');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final difficultyColor = _getDifficultyColor(context);

    final progress = progressTotal > 0 ? progressCurrent / progressTotal : 0.0;
    final isExpired = expiresAt != null &&
        expiresAt!.isBefore(DateTime.now()) &&
        !isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _requiresManualAction ? onManualComplete : null,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? primaryColor.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _categoryEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                        ? Colors.grey[400]
                                        : onSurface,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildBadge(
                                      difficulty.toUpperCase(),
                                      difficultyColor,
                                      isOutlined: true,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      '+$xpReward XP',
                                      primaryColor,
                                      icon: Icons.stars_rounded,
                                    ),
                                    if (!rewardClaimed) ...[
                                      const SizedBox(width: 8),
                                      _buildBadge(
                                        '+${_getEnergyReward()} ⚡',
                                        Colors.amber[800]!,
                                        icon: Icons.bolt_rounded,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle_rounded,
                              color: primaryColor,
                              size: 28,
                            )
                          else if (_requiresManualAction)
                             const Icon(
                              Icons.circle_outlined,
                              color: Colors.grey,
                              size: 28,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

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
                                      ? primaryColor
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
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted
                                    ? primaryColor
                                    : isExpired
                                        ? Colors.grey
                                        : difficultyColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Footer with actions (only show incremental controls if not completed)
                      if (!isCompleted && !isExpired && _requiresManualAction && progressTotal > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (onIncrementProgress != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => onIncrementProgress!(1),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('+1'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: difficultyColor,
                                    side: BorderSide(
                                        color: difficultyColor.withOpacity(0.3)),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ] else if (!isCompleted && !isExpired && !_requiresManualAction && _timeRemaining.isNotEmpty) ...[
                         const SizedBox(height: 16),
                         Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: Colors.grey[400],
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
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color,
      {bool isOutlined = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isOutlined ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
