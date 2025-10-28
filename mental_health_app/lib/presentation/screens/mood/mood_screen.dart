import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class MoodScreen extends StatefulWidget {
  final int characterId;
  final String characterGender;
  final int characterNumber;
  final Function(String mood)? onMoodSelected; // Add this line

  const MoodScreen({
    super.key,
    required this.characterId,
    required this.characterGender,
    required this.characterNumber,
    this.onMoodSelected, // Add this line
  });

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _noteController = TextEditingController();
  late TabController _tabController;

  // Character details from onboarding
  int _characterId = 1;
  String _characterGender = 'Boy';
  int _characterNumber = 1;
  bool _characterLoaded = false;

  bool _isLoading = false;
  bool _isLoadingHistory = true;
  List<dynamic> _moodHistory = [];
  Map<String, dynamic>? _moodStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharacterDetails();
    _loadData();
  }

  Future<void> _loadCharacterDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _characterId = prefs.getInt('selected_character_id') ?? 1;
        _characterGender =
            prefs.getString('selected_character_gender') ?? 'Boy';
        _characterNumber = prefs.getInt('selected_character_number') ?? 1;
        _characterLoaded = true;
      });
    } catch (e) {
      print('Error loading character details: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Dynamically generate moods map based on selected character
  Map<String, Map<String, dynamic>> get _moods {
    // Base path based on gender
    final String basePath = 'assets/images/${_characterGender}_Gif_33FPS';

    return {
      'happy': {
        'icon': Icons.sentiment_very_satisfied,
        'color': const Color(0xFFFFD54F), // Yellow
        'label': 'Happy',
        'gifPath': '$basePath/Happy$_characterGender$_characterNumber.gif',
      },
      'calm': {
        'icon': Icons.self_improvement,
        'color': const Color(0xFF42A5F5), // Blue
        'label': 'Calm',
        'gifPath': '$basePath/Calm$_characterGender$_characterNumber.gif',
      },
      'tired': {
        'icon': Icons.bedtime,
        'color': const Color(0xFF78909C), // Blue Grey
        'label': 'Tired',
        'gifPath': '$basePath/Tired$_characterGender$_characterNumber.gif',
      },
      'anxious': {
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFFFA726), // Orange
        'label': 'Anxious',
        'gifPath': '$basePath/Anxious$_characterGender$_characterNumber.gif',
      },
      'sad': {
        'icon': Icons.sentiment_dissatisfied,
        'color': const Color(0xFF9575CD), // Purple
        'label': 'Sad',
        'gifPath': '$basePath/Sad$_characterGender$_characterNumber.gif',
      },
      'angry': {
        'icon': Icons.sentiment_very_dissatisfied,
        'color': const Color(0xFFEF5350), // Red
        'label': 'Angry',
        'gifPath': '$basePath/Angry$_characterGender$_characterNumber.gif',
      },
    };
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

  void _showNoteDialog(String mood) {
    _noteController.clear(); // Clear any previous text

    final moodData = _moods[mood]!;
    final Color moodColor = moodData['color'] as Color;
    final String moodLabel = moodData['label'] as String;
    final String? gifPath = moodData['gifPath'] as String?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 400, // Fixed width
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 500, // Fixed max height
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Centered Mood Header with GIF
              Center(
                child: Column(
                  children: [
                    // Use character GIF if available, else fallback to icon
                    if (gifPath != null && _characterLoaded)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: moodColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: moodColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            gifPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if image fails
                              return Icon(moodData['icon'],
                                  color: moodColor, size: 80);
                            },
                          ),
                        ),
                      )
                    else
                      Icon(moodData['icon'], color: moodColor, size: 80),

                    const SizedBox(height: 8),
                    Text(
                      moodLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: moodColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a note (Optional):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A4B80),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              const SizedBox(height: 12),

              // Fixed-height text field that doesn't expand
              Container(
                height: 120, // Fixed height for text field
                decoration: BoxDecoration(
                  border: Border.all(
                    color: moodColor,
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: null, // Allow multiple lines
                  expands: true, // Fill the available space
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: "I'm feeling...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    filled: false,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0A4B80),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moodColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logMood(mood);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logMood(String mood) async {
    setState(() => _isLoading = true);

    try {
      await _apiService.createMood({
        'mood': mood,
        'note': _noteController.text.trim(),
      });

      if (!mounted) return;

      // Notify the HomeScreen about the selected mood
      if (widget.onMoodSelected != null) {
        widget.onMoodSelected!(mood);
        print('🎭 MOOD SCREEN: Callback triggered with mood: $mood');
      }

      // Check for achievements silently
      _apiService.checkAchievements();
      _noteController.clear();

      // Reload data
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log mood: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336),
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
    return SafeArea(
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
                    color: Color(0xFF0A4B80), // Dark blue for contrast
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track your emotions and see patterns',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0A4B80), // Dark blue for contrast
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 204),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF5CACEE),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF0A4B80),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Text(
                    'Log Mood',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Tab(
                  child: Text(
                    'History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    );
  }

  Widget _buildLogMoodTab() {
    if (!_characterLoaded) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mood Selection Grid with Character GIFs
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
              final String? gifPath = moodData['gifPath'] as String?;

              return GestureDetector(
                onTap: () {
                  // Show note dialog
                  _showNoteDialog(mood);
                },
                child: Container(
                  decoration: BoxDecoration(
                    // Use the mood color as background with high opacity
                    color: (moodData['color'] as Color).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (moodData['color'] as Color).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border:
                        Border.all(color: moodData['color'] as Color, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show GIF if available, otherwise show icon
                      if (gifPath != null)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: (moodData['color'] as Color)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              gifPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image fails
                                return Icon(moodData['icon'],
                                    size: 35, color: Colors.white);
                              },
                            ),
                          ),
                        )
                      else
                        Icon(
                          moodData['icon'],
                          size: 45,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        moodData['label'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Color(0x88000000),
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
              color: Colors.white.withValues(alpha: 150),
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
          final moodType = mood['mood'] as String;
          final moodData = _moods[moodType];
          final note = mood['note'];
          final loggedAt = DateTime.parse(mood['logged_at']);

          // Get GIF path for this mood based on character selection
          final gifPath = moodData?['gifPath'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: (moodData?['color'] as Color?)?.withValues(alpha: 76) ??
                    Colors.grey.withValues(alpha: 76),
              ),
            ),
            child: Row(
              children: [
                // Character GIF or fallback icon
                if (gifPath != null && _characterLoaded)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (moodData?['color'] as Color?) ?? Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        gifPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (moodData?['color'] as Color?)
                                      ?.withValues(alpha: 25) ??
                                  Colors.grey.withValues(alpha: 25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              moodData?['icon'] ?? Icons.mood,
                              color: moodData?['color'] ?? Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (moodData?['color'] as Color?)
                              ?.withValues(alpha: 25) ??
                          Colors.grey.withValues(alpha: 25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (moodData?['color'] as Color?)
                                ?.withValues(alpha: 127) ??
                            Colors.grey.withValues(alpha: 127),
                      ),
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
                              color: Color(0xFF0A4B80),
                            ),
                          ),
                          Text(
                            _formatDate(loggedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(
                                  0xFF0A4B80), // Darker for better contrast
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
                            color:
                                Color(0xFF0A4B80), // Darker for better contrast
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
        color: Colors.white.withValues(alpha: 220),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: const Color(0xFF5CACEE).withValues(alpha: 76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A4B80),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$totalEntries mood logs',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0A4B80), // Darker for better contrast
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: moodData?['color'] ?? const Color(0xFF0A4B80),
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color:
                              Color(0xFF0A4B80), // Darker for better contrast
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        moodData?['color'] ?? const Color(0xFF5CACEE),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          })
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
