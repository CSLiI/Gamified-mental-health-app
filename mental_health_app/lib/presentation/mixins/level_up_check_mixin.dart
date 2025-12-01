import 'package:flutter/material.dart';
import '../widgets/level_up_dialog.dart';
import '../../data/services/api_service.dart';

/// Mixin that provides level-up checking functionality to any screen
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with LevelUpCheckMixin {
///   @override
///   Widget build(BuildContext context) {
///     return YourWidget();
///   }
///
///   Future<void> someActionThatGivesXP() async {
///     // ... perform action that awards XP
///     await checkLevelUp(); // Check if user leveled up
///   }
/// }
/// ```
mixin LevelUpCheckMixin<T extends StatefulWidget> on State<T> {
  final ApiService _levelUpApiService = ApiService();

  /// Checks if the user has leveled up and shows the celebration dialog
  ///
  /// Call this after any action that awards XP:
  /// - Daily check-in
  /// - Quest completion
  /// - Achievement unlock
  /// - Mystery box opening
  /// - Journal entry
  /// - Mood log
  /// - Todo completion
  Future<void> checkLevelUp() async {
    try {
      final result = await _levelUpApiService.checkLevelUp();

      if (result['leveled_up'] == true && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LevelUpDialog(
            oldLevel: result['old_level'],
            newLevel: result['new_level'],
            milestoneXp: result['milestone_xp'] ?? 0,
            rewardsUnlocked: List<Map<String, dynamic>>.from(
                result['rewards_unlocked'] ?? []),
            petsUnlocked:
                List<Map<String, dynamic>>.from(result['pets_unlocked'] ?? []),
          ),
        );
      }
    } catch (e) {
      print('Error checking level up: $e');
      // Fail silently - level-up check is not critical
    }
  }

  /// Checks level-up with a small delay (useful when showing another dialog first)
  Future<void> checkLevelUpDelayed(
      {Duration delay = const Duration(milliseconds: 500)}) async {
    await Future.delayed(delay);
    await checkLevelUp();
  }
}
