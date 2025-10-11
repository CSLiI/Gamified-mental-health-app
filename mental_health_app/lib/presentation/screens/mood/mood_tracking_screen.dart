// lib/presentation/screens/mood/mood_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  String? _selectedMood;
  double _intensity = 3.0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  final List<MoodOption> _moods = [
    MoodOption(
      id: 'happy',
      emoji: '😊',
      label: 'Happy',
      color: AppColors.moodHappy,
    ),
    MoodOption(
      id: 'sad',
      emoji: '😢',
      label: 'Sad',
      color: AppColors.moodSad,
    ),
    MoodOption(
      id: 'anxious',
      emoji: '😰',
      label: 'Anxious',
      color: AppColors.moodAnxious,
    ),
    MoodOption(
      id: 'calm',
      emoji: '😌',
      label: 'Calm',
      color: AppColors.moodCalm,
    ),
    MoodOption(
      id: 'angry',
      emoji: '😠',
      label: 'Angry',
      color: AppColors.moodAngry,
    ),
    MoodOption(
      id: 'tired',
      emoji: '😴',
      label: 'Tired',
      color: AppColors.moodTired,
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitMood() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Submit to API
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood logged successfully! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Color get _selectedColor {
    if (_selectedMood == null) return AppColors.primary;
    return _moods.firstWhere((m) => m.id == _selectedMood).color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _selectedColor.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date & Time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today, ${_formatDate()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 32),

                // Mood Selection Title
                Text(
                  'Select your mood',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // Mood Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _moods.length,
                  itemBuilder: (context, index) {
                    return _MoodCard(
                      mood: _moods[index],
                      isSelected: _selectedMood == _moods[index].id,
                      onTap: () {
                        setState(() => _selectedMood = _moods[index].id);
                      },
                    ).animate(delay: (index * 100).ms).scale().fadeIn();
                  },
                ),

                const SizedBox(height: 32),

                // Intensity Slider
                if (_selectedMood != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Intensity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_intensity.toInt()}/5',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _selectedColor,
                            inactiveTrackColor: _selectedColor.withOpacity(0.2),
                            thumbColor: _selectedColor,
                            overlayColor: _selectedColor.withOpacity(0.2),
                            trackHeight: 8,
                          ),
                          child: Slider(
                            value: _intensity,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            onChanged: (value) {
                              setState(() => _intensity = value);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mild',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              'Intense',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(delay: 300.ms),

                  const SizedBox(height: 24),

                  // Optional Note
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add a note (optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'What\'s on your mind?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(delay: 400.ms),

                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Mood',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ).animate().fadeIn(delay: 500.ms),
                ],

                const SizedBox(height: 24),

                // Tips Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.info,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your mood daily to understand patterns and triggers',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class MoodOption {
  final String id;
  final String emoji;
  final String label;
  final Color color;

  MoodOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

class _MoodCard extends StatelessWidget {
  final MoodOption mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? mood.color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? mood.color : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mood.emoji,
              style: TextStyle(
                fontSize: isSelected ? 56 : 48,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? mood.color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}