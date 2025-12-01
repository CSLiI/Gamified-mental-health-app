import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class MysteryBoxDialog extends StatefulWidget {
  final String boxType; // bronze, silver, gold, legendary
  final Function(int boxId) onOpen;

  const MysteryBoxDialog({
    Key? key,
    required this.boxType,
    required this.onOpen,
  }) : super(key: key);

  @override
  State<MysteryBoxDialog> createState() => _MysteryBoxDialogState();
}

class _MysteryBoxDialogState extends State<MysteryBoxDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openController;
  late AnimationController _revealController;
  late AnimationController _confettiController;

  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _revealScaleAnimation;

  bool _isOpening = false;
  bool _isRevealed = false;
  Map<String, dynamic>? _reward;

  @override
  void initState() {
    super.initState();

    // Shake animation (idle)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Open animation
    _openController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _openController,
      curve: Curves.elasticOut,
    ));

    // Reveal animation
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _revealScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    ));

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _openController.dispose();
    _revealController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _openBox(int boxId) async {
    if (_isOpening) return;

    setState(() => _isOpening = true);
    _shakeController.stop();

    // Shake intensely
    await _shakeController.forward();
    await _shakeController.reverse();
    await _shakeController.forward();
    await _shakeController.reverse();

    // Scale up and trigger backend call
    await _openController.forward();

    try {
      final result = await widget.onOpen(boxId);

      setState(() {
        _reward = result;
        _isRevealed = true;
      });

      // Start reveal animation
      await _revealController.forward();

      // Start confetti for rare rewards
      if (_isRareReward()) {
        _confettiController.repeat();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open box: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  bool _isRareReward() {
    if (_reward == null) return false;
    final rewardType = _reward!['reward_type'];
    return rewardType == 'pet' || widget.boxType == 'legendary';
  }

  Color _getBoxColor() {
    switch (widget.boxType.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return Colors.grey[400]!;
      case 'gold':
        return Colors.amber;
      case 'legendary':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardIcon() {
    if (_reward == null) return Icons.card_giftcard;

    final rewardType = _reward!['reward_type'];
    switch (rewardType) {
      case 'xp':
        return Icons.stars;
      case 'pet':
        return Icons.pets;
      case 'cosmetic':
        return Icons.brush;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getRewardText() {
    if (_reward == null) return '';

    final rewardType = _reward!['reward_type'];
    switch (rewardType) {
      case 'xp':
        return '+${_reward!['xp_amount']} XP';
      case 'pet':
        return '${_reward!['pet_emoji']} ${_reward!['pet_name']}';
      case 'cosmetic':
        return _reward!['reward_name'];
      default:
        return 'Unknown Reward';
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxColor = _getBoxColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Confetti effect
          if (_isRevealed && _isRareReward())
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(_confettiController.value),
                  );
                },
              ),
            ),

          // Main content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isRevealed) ...[
                  // Title
                  Text(
                    'Mystery Box',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: boxColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.boxType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: boxColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Box animation
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _shakeAnimation.value,
                        child: child,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _openController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: _isOpening
                            ? null
                            : () => _openBox(1), // TODO: Pass actual box ID
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                boxColor,
                                boxColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: boxColor.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Instructions
                  Text(
                    _isOpening ? 'Opening...' : 'Tap to open!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  // Reward revealed
                  const Text(
                    'You received:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reward display
                  AnimatedBuilder(
                    animation: _revealScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _revealScaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRareReward()
                              ? [Colors.purple, Colors.deepPurple]
                              : [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRareReward()
                                    ? Colors.purple
                                    : AppColors.primary)
                                .withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getRewardIcon(),
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getRewardText(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_reward!['reward_type'] == 'pet') ...[
                            const SizedBox(height: 8),
                            const Text(
                              'New pet unlocked!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Claim button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _reward),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final math.Random _random = math.Random();

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = _random.nextDouble() * size.width;
      final y = (animationValue * size.height + i * 20) % size.height;
      final color = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
      ][i % 6];

      paint.color = color;

      final rotation = animationValue * math.pi * 2 + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        const Rect.fromLTWH(-3, -6, 6, 12),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
