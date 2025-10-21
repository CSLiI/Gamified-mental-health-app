import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _noteController = TextEditingController();
  late TabController _tabController;

  String? _selectedMood;
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  List<dynamic> _moodHistory = [];
  Map<String, dynamic>? _moodStats;

  final Map<String, Map<String, dynamic>> _moods = {
    'happy': {
      'icon': Icons.sentiment_very_satisfied,
      'color': AppColors.moodHappy,
      'label': 'Happy',
    },
    'calm': {
      'icon': Icons.self_improvement,
      'color': AppColors.moodCalm,
      'label': 'Calm',
    },
    'tired': {
      'icon': Icons.bedtime,
      'color': AppColors.moodTired,
      'label': 'Tired',
    },
    'anxious': {
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.moodAnxious,
      'label': 'Anxious',
    },
    'sad': {
      'icon': Icons.sentiment_dissatisfied,
      'color': AppColors.moodSad,
      'label': 'Sad',
    },
    'angry': {
      'icon': Icons.sentiment_very_dissatisfied,
      'color': AppColors.moodAngry,
      'label': 'Angry',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMoodHistory(),
      _loadMoodStats(),
    ]);
  }

  Future<void> _loadMoodHistory() async {
    try {
      final moods = await _apiService.getMoodLogs(limit: 20);
      setState(() {
        _moodHistory = moods;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadMoodStats() async {
    try {
      final stats = await _apiService.getMoodStatistics(days: 7);
      setState(() => _moodStats = stats);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _logMood() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.createMood({
        'mood': _selectedMood,
        'note': _noteController.text.trim(),
      });

      if (!mounted) return;

      // Check for achievements silently
      _apiService.checkAchievements();

      _noteController.clear();
      setState(() => _selectedMood = null);

      // Reload data
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log mood: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB0E0FF), // Lighter baby blue at top
              Color(0xFF89CFF0), // Baby blue at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Color(0x55000000),
                            offset: Offset(1, 1),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track your emotions and see patterns',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Color(0x55000000),
                            offset: Offset(1, 1),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar - Styled like todo screen
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF5CACEE), // Baby blue theme
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(
                      0xFF0A4B80), // Darker blue for better contrast
                  indicatorSize: TabBarIndicatorSize.tab, // Match Todo screen
                  dividerColor: Colors.transparent, // Match Todo screen
                  tabs: const [
                    Tab(
                      child: Text(
                        'Log Mood',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogMoodTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mood Selection Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: _moods.length,
            itemBuilder: (context, index) {
              final entry = _moods.entries.elementAt(index);
              final mood = entry.key;
              final moodData = entry.value;
              final isSelected = _selectedMood == mood;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMood = mood);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? moodData['color']
                        : Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? moodData['color'] : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? (moodData['color'] as Color).withValues(alpha: .3)
                            : Colors.black.withValues(alpha: .05),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        moodData['icon'],
                        size: 40,
                        color: isSelected ? Colors.white : moodData['color'],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        moodData['label'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(
                                  0xFF0A4B80), // Dark blue for better contrast
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Note Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a note (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4B80), // Dark blue for better contrast
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withAlpha(100)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withAlpha(100)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF5CACEE), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0A4B80),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Log Mood Button
          ElevatedButton(
            onPressed: _isLoading ? null : _logMood,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5CACEE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5CACEE),
                    ),
                  )
                : const Text(
                    'Log Mood',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          // Stats Preview
          if (_moodStats != null) ...[
            const SizedBox(height: 24),
            _buildStatsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ));
    }

    if (_moodHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood_outlined,
              size: 80,
              color: Colors.white.withAlpha(150),
            ),
            const SizedBox(height: 16),
            const Text(
              'No mood logs yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Color(0x55000000),
                    offset: Offset(1, 1),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your moods!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Color(0x55000000),
                    offset: Offset(1, 1),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF5CACEE),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: _moodHistory.length,
        itemBuilder: (context, index) {
          final mood = _moodHistory[index];
          final moodType = mood['mood'];
          final moodData = _moods[moodType];
          final note = mood['note'];
          final loggedAt = DateTime.parse(mood['logged_at']);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (moodData?['color'] as Color?)?.withValues(alpha: .1) ??
                            Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    moodData?['icon'] ?? Icons.mood,
                    color: moodData?['color'] ?? Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            moodData?['label'] ?? moodType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                  0xFF0A4B80), // Dark blue for better contrast
                            ),
                          ),
                          Text(
                            _formatDate(loggedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54, // Better contrast
                            ),
                          ),
                        ],
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54, // Better contrast
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalEntries = _moodStats!['total_entries'] ?? 0;
    final distribution =
        _moodStats!['mood_distribution'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A4B80), // Dark blue for better contrast
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$totalEntries mood logs',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54, // Better contrast
            ),
          ),
          const SizedBox(height: 16),
          ...distribution.entries.map((entry) {
            final mood = entry.key;
            final count = entry.value;
            final percentage = totalEntries > 0 ? (count / totalEntries) : 0.0;
            final moodData = _moods[mood];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        moodData?['label'] ?? mood,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(
                              0xFF0A4B80), // Dark blue for better contrast
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54, // Better contrast
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.withAlpha(50),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        moodData?['color'] ?? const Color(0xFF5CACEE),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
