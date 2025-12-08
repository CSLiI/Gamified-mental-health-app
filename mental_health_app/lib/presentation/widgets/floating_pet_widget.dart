import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';

class FloatingPetWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const FloatingPetWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<FloatingPetWidget> createState() => _FloatingPetWidgetState();
}

class _FloatingPetWidgetState extends State<FloatingPetWidget>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _activePet;
  bool _isLoading = true;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _loadActivePet();

    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadActivePet() async {
    try {
      final myPets = await _apiService.getMyPets();

      setState(() {
        final activePet = myPets.firstWhere(
          (p) => p['is_active'] == true,
          orElse: () => <String, dynamic>{},
        );

        if (activePet.isNotEmpty) {
          _activePet = activePet as Map<String, dynamic>;
        }
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading active pet: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getAffectionColor(int affection) {
    if (affection >= 80) return Colors.red;
    if (affection >= 60) return Colors.pink;
    if (affection >= 40) return Colors.orange;
    if (affection >= 20) return Colors.yellow;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if loading or no active pet
    if (_isLoading || _activePet == null) {
      return const SizedBox.shrink();
    }

    final affection = _activePet!['affection_level'] ?? 0;
    final affectionColor = _getAffectionColor(affection);

    return Positioned(
      bottom: 80, // Above bottom nav bar
      right: 16,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: affectionColor,
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                // Pet emoji
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  child: Text(
                    _activePet!['emoji'],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),

                // Affection indicator (heart with level)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: affectionColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Affection level number
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: affectionColor, width: 2),
                    ),
                    child: Text(
                      affection.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: affectionColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Alternative version that follows cursor/screen position
class FloatingPetFollower extends StatefulWidget {
  final VoidCallback? onTap;

  const FloatingPetFollower({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<FloatingPetFollower> createState() => _FloatingPetFollowerState();
}

class _FloatingPetFollowerState extends State<FloatingPetFollower>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _activePet;
  bool _isLoading = true;
  late AnimationController _idleController;
  Offset _targetPosition = const Offset(300, 500);
  Offset _currentPosition = const Offset(300, 500);

  @override
  void initState() {
    super.initState();
    _loadActivePet();

    // Idle animation (subtle movement)
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _loadActivePet() async {
    try {
      final myPets = await _apiService.getMyPets();

      setState(() {
        final activePet = myPets.firstWhere(
          (p) => p['is_active'] == true,
          orElse: () => <String, dynamic>{},
        );

        if (activePet.isNotEmpty) {
          _activePet = activePet as Map<String, dynamic>;
        }
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading active pet: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updatePosition(Offset newPosition) {
    setState(() {
      _targetPosition = newPosition;
      // Smoothly move towards target
      _currentPosition = Offset(
        _currentPosition.dx + (_targetPosition.dx - _currentPosition.dx) * 0.1,
        _currentPosition.dy + (_targetPosition.dy - _currentPosition.dy) * 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _activePet == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          _updatePosition(Offset(
            _currentPosition.dx + details.delta.dx,
            _currentPosition.dy + details.delta.dy,
          ));
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, child) {
            final angle = math.sin(_idleController.value * 2 * math.pi) * 0.1;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _activePet!['emoji'],
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}
