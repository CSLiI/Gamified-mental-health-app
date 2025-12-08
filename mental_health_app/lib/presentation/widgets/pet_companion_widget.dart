import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../core/providers/pet_provider.dart';
import '../../core/constants/app_colors.dart';

class PetCompanionWidget extends StatefulWidget {
  const PetCompanionWidget({super.key});

  @override
  State<PetCompanionWidget> createState() => _PetCompanionWidgetState();
}

class _PetCompanionWidgetState extends State<PetCompanionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showMenu = false;
  String? _chatMessage;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
      if (_showMenu) {
        _showRandomChat();
      } else {
        _chatMessage = null;
      }
    });
  }

  void _showRandomChat() {
    final messages = [
      "Hi there! 👋",
      "I'm hungry! 🍖",
      "Let's play! 🎾",
      "You're doing great! ⭐",
      "Feed me please! 😋",
    ];
    setState(() {
      _chatMessage = messages[DateTime.now().millisecond % messages.length];
    });
  }

  void _showChat(String message) {
    setState(() => _chatMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _chatMessage == message) {
        setState(() => _chatMessage = null);
      }
    });
  }

  Future<void> _feed(PetProvider provider) async {
    final result = await provider.feed();
    if (result['success'] == true) {
      _showChat("Yummy! 🍖");
    }
  }

  Future<void> _pet(PetProvider provider) async {
    final affection = await provider.interact();
    if (affection > 0) {
      _showChat("I love you! ❤️");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, provider, child) {
        final activePet = provider.activePet;

        if (activePet == null) {
          return GestureDetector(
            onTap: () {
              // Navigate to rewards tab to select a pet
              // For now just show a snackbar
              // SnackBar removed for cleaner UI
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.grey),
            ),
          );
        }

        final hunger = activePet['hunger'] as int? ?? 50;
        final affection = activePet['affection_level'] as int? ?? 0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Chat Bubble
            if (_chatMessage != null)
              Positioned(
                top: -60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _chatMessage!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      CustomPaint(
                        painter: TrianglePainter(),
                        size: const Size(10, 10),
                      ),
                    ],
                  ),
                ),
              ),

            // Menu Buttons
            if (_showMenu) ...[
              // Feed Button
              Positioned(
                left: -60,
                child: _buildMenuButton(
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  label: 'Feed',
                  onTap: () => _feed(provider),
                ),
              ),
              // Pet Button
              Positioned(
                right: -60,
                child: _buildMenuButton(
                  icon: Icons.favorite,
                  color: Colors.pink,
                  label: 'Pet',
                  onTap: () => _pet(provider),
                ),
              ),
              // Hunger Bar
              Positioned(
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 100 * (hunger / 100),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Hunger',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Pet Avatar
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: _showMenu ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (activePet['lottie_file'] != null)
                      Lottie.asset(
                        activePet['lottie_file'],
                        controller: _controller,
                        onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          _controller.repeat();
                        },
                        fit: BoxFit.contain,
                      )
                    else
                      Text(
                        activePet['emoji'] ?? '🐾',
                        style: const TextStyle(fontSize: 48),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
