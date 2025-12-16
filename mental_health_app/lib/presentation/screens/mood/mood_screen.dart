import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/utils/image_cache_manager.dart';
import '../../widgets/level_up_dialog.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/character_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final Debouncer _moodTapDebouncer = Debouncer(milliseconds: 250);

  bool _isLoading = false;
  bool _isLoadingHistory = true;
  List<dynamic> _moodHistory = [];
  Map<String, dynamic>? _moodStats;
  String _timeRange = 'week'; // 'week', 'month', '3months', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(); // Just load mood data, character data comes from Provider
    
    // Trigger initial character load if needed (though Profile/Home likely did it)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       context.read<CharacterProvider>().loadCharacter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }


  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Dynamically generate moods map based on selected character
  Map<String, Map<String, dynamic>> _getMoods(String gender, int number) {
    // Base path based on gender - format: Boy_Gif_33FPS/HappyBoy1.gif
    final String basePath = 'assets/images/${gender}_Gif_33FPS';

    return {
      'happy': {
        'icon': Icons.sentiment_very_satisfied,
        'color': const Color(0xFFFFD54F), // Yellow
        'label': 'Happy',
        'gifPath': '$basePath/Happy$gender$number.gif',
      },
      'calm': {
        'icon': Icons.self_improvement,
        'color': const Color(0xFF42A5F5), // Blue
        'label': 'Calm',
        'gifPath': '$basePath/Calm$gender$number.gif',
      },
      'tired': {
        'icon': Icons.bedtime,
        'color': const Color(0xFF78909C), // Blue Grey
        'label': 'Tired',
        'gifPath': '$basePath/Tired$gender$number.gif',
      },
      'anxious': {
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFFFA726), // Orange
        'label': 'Anxious',
        'gifPath':
            '$basePath/Anxious$gender$number.gif',
      },
      'sad': {
        'icon': Icons.sentiment_dissatisfied,
        'color': const Color(0xFF9575CD), // Purple
        'label': 'Sad',
        'gifPath': '$basePath/Sad$gender$number.gif',
      },
      'angry': {
        'icon': Icons.sentiment_very_dissatisfied,
        'color': const Color(0xFFEF5350), // Red
        'label': 'Angry',
        'gifPath': '$basePath/Angry$gender$number.gif',
      },
    };
  }

  final Map<String, List<String>> _moodMotivations = {
    'happy': [
      "Your smile lights up the world!",
      "Keep shining like the star you are!",
      "Spread that joy around!",
      "You are radiant today!",
      "Happiness looks amazing on you!",
      "Enjoy every moment of this feeling!",
      "Ride this wave of positivity!",
    ],
    'calm': [
      "Peace begins with a deep breath.",
      "Stay centered and grounded.",
      "Serenity is a superpower.",
      "Embrace the stillness within.",
      "You are exactly where you need to be.",
      "Quiet the mind, and the soul will speak.",
      "Tranquility is strength.",
    ],
    'tired': [
      "Rest is not laziness, it's medicine.",
      "Recharge your batteries, you deserve it.",
      "Listen to your body's whisper.",
      "Sleep is the best meditation.",
      "It's okay to slow down and pause.",
      "Dream big, but sleep deep first.",
      "Tomorrow is a fresh start.",
    ],
    'anxious': [
      "One step at a time is enough.",
      "You are safe effectively right now.",
      "This feeling will pass like a cloud.",
      "Breathe in courage, breathe out fear.",
      "You are stronger than your anxiety.",
      "Focus on the present moment.",
      "You've survived 100% of your bad days.",
    ],
    'sad': [
      "Tears are how our heart speaks.",
      "It's okay not to be okay sometimes.",
      "You are loved more than you know.",
      "The sun will rise again tomorrow.",
      "Be gentle with yourself today.",
      "Sending you a warm virtual hug.",
      "Rainstorms help the flowers grow.",
    ],
    'angry': [
      "Channel this energy into something new.",
      "Deep breaths. You are in control.",
      "Letting go is the real victory.",
      "Peace is a choice you can make.",
      "This anger does not define you.",
      "Walk it off and find your center.",
      "Choose to be kind to yourself.",
    ],
  };

  Future<void> _loadData() async {
    await Future.wait([
      _loadMoodHistory(),
      _loadMoodStats(),
    ]);
  }

  Future<void> _loadMoodHistory() async {
    try {
      // Check cache first
      final cacheKey = 'mood_history_$_timeRange';
      final cachedMoods = await CacheService().get<List<dynamic>>(
        cacheKey,
        maxAge: CacheService.shortCache,
      );

      if (cachedMoods != null && mounted) {
        setState(() {
          _moodHistory = cachedMoods;
          _isLoadingHistory = false;
        });
      }

      // Fetch fresh data in background with time range filter
      int? limit;
      switch (_timeRange) {
        case 'week':
          limit = 50; // Last 7 days worth
          break;
        case 'month':
          limit = 100; // Last 30 days
          break;
        case '3months':
          limit = 300; // Last 90 days
          break;
        case 'all':
          limit = null; // All time (no limit)
          break;
      }
      final moods = await _apiService.getMoodLogs(limit: limit);

      // Filter by date range
      List<dynamic> filteredMoods = moods;
      if (_timeRange != 'all') {
        final now = DateTime.now();
        final daysAgo = _timeRange == 'week'
            ? 7
            : _timeRange == 'month'
                ? 30
                : 90;
        final cutoffDate = now.subtract(Duration(days: daysAgo));

        filteredMoods = moods.where((mood) {
          final loggedAt = DateTime.parse(mood['logged_at']);
          return loggedAt.isAfter(cutoffDate);
        }).toList();
      }

      // Update cache with time range key
      await CacheService().set(cacheKey, filteredMoods);

      if (mounted) {
        setState(() {
          _moodHistory = filteredMoods;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _loadMoodStats() async {
    try {
      // Check cache first
      final cachedStats = await CacheService().get<Map<String, dynamic>>(
        'mood_stats',
        maxAge: CacheService.shortCache,
      );

      if (cachedStats != null && mounted) {
        setState(() => _moodStats = cachedStats);
      }

      // Fetch fresh data in background
      final stats = await _apiService.getMoodStatistics(days: 7);

      // Update cache
      await CacheService().set('mood_stats', stats);

      if (mounted) {
        setState(() => _moodStats = stats);
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _showNoteDialog(String mood) {
    _noteController.clear(); // Clear any previous text

    final provider = context.read<CharacterProvider>();
    final moods = _getMoods(provider.characterGender, provider.characterNumber);
    final moodData = moods[mood]!;
    final Color moodColor = moodData['color'] as Color;
    final String moodLabel = moodData['label'] as String;
    final String? gifPath = moodData['gifPath'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 400.w),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Centered Mood Header with GIF
                  Center(
                    child: Column(
                      children: [
                        // Use character GIF if available, else fallback to icon
                        if (gifPath != null)
                          Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(
                              color: moodColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: moodColor, width: 3.w),
                              boxShadow: [
                                BoxShadow(
                                  color: moodColor.withOpacity(0.3),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17.r),
                              child: ImageCacheManager().buildCachedImage(
                                assetPath: gifPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Icon(moodData['icon'], color: moodColor, size: 60.sp),

                        SizedBox(height: 8.h),
                        Text(
                          moodLabel,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: moodColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add a note (Optional):',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A4B80),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Text field with fixed height
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: moodColor,
                        width: 2.5.w,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.grey[50],
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: "I'm feeling...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12.w),
                        filled: false,
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF0A4B80),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Action Buttons - Always visible
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 12.h),
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
      }

      // Check for achievements silently
      final achievementResult = await _apiService.checkAchievements();
      _noteController.clear();

      // Update quest progress for mood category
      await _apiService.updateQuestProgress('mood', increment: 1);

      // Refresh global provider to update Home/Profile screens immediately
      if (mounted) {
        await context.read<MoodProvider>().loadMood(forceRefresh: true);
      }

      // Reload data
      await _loadData();

      // Check for level-up if XP was gained
      if (achievementResult['xp_earned'] != null &&
          achievementResult['xp_earned'] > 0) {
        await _checkLevelUp();
      }

      // Add system notification for later viewing
      if (mounted) {
         final motivation = _getMotivation(mood);
         final notificationProvider = context.read<NotificationProvider>();
         notificationProvider.addSystemNotification(
            title: "Echo's Encouragement",
            message: motivation,
            type: NotificationType.systemMotivation,
            redirectRoute: '/mood',
         );
         
         // Show immediate motivational dialog
         _showMotivationDialog(mood);
      }

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

  String _getMotivation(String mood) {
    final motivations = _moodMotivations[mood] ?? ["You're doing great!"];
    return (motivations..shuffle()).first;
  }

  Future<void> _checkLevelUp() async {
    try {
      final result = await _apiService.checkLevelUp();

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
            petsUnlocked: List<Map<String, dynamic>>.from(result['pets_unlocked'] ?? []),
          ),
        );
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _showMotivationDialog(String mood) {
    final motivations = _moodMotivations[mood] ?? ["You're doing great!"];
    final randomQuote = (motivations..shuffle()).first;
    
    final provider = context.read<CharacterProvider>();
    final moods = _getMoods(provider.characterGender, provider.characterNumber);
    final moodData = moods[mood]!;
    
    final Color moodColor = moodData['color'] as Color;
    final String? gifPath = moodData['gifPath'] as String?;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: moodColor.withOpacity(0.3),
                      blurRadius: 20.r,
                      spreadRadius: 5.r,
                    ),
                  ],
                  border: Border.all(color: moodColor.withOpacity(0.5), width: 2.w),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Character Animation
                    if (gifPath != null)
                      Container(
                        width: 140.w,
                        height: 140.w,
                        margin: EdgeInsets.only(bottom: 20.h),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: moodColor, width: 3.w),
                        ),
                        child: ClipOval(
                          child: ImageCacheManager().buildCachedImage(
                            assetPath: gifPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    Text(
                      moodData['label'],
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: moodColor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '"$randomQuote"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                            'Continue',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeProvider.primaryColor.withOpacity(0.08),
                themeProvider.secondaryColor.withOpacity(0.08),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(24.0.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling?',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface, // Dark blue for contrast
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Track your emotions and see patterns',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface, // Dark blue for contrast
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B8BA8),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.all(4.w),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Text(
                          'Log Mood',
                        ),
                      ),
                      Tab(
                        child: Text(
                          'History',
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
        );
      },
    );
  }

  Widget _buildLogMoodTab() {
    return Consumer<CharacterProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ));
        }

        final moods = _getMoods(provider.characterGender, provider.characterNumber);

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mood Selection Grid with Character GIFs
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
                childAspectRatio: 0.85, // Taller to prevent overflow
            ),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final entry = moods.entries.elementAt(index);
              final mood = entry.key;
              final moodData = entry.value;
              final String? gifPath = moodData['gifPath'] as String?;
              return GestureDetector(
                onTap: () {
                  _moodTapDebouncer.run(() {
                    // Show note dialog
                    _showNoteDialog(mood);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    // Use the mood color as background with high opacity
                    color: (moodData['color'] as Color).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (moodData['color'] as Color).withOpacity(0.4),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                    border:
                        Border.all(color: moodData['color'] as Color, width: 3.w),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show GIF if available, otherwise show icon
                      if (gifPath != null)
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            color: (moodData['color'] as Color)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: ImageCacheManager().buildCachedImage(
                              assetPath: gifPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Icon(
                          moodData['icon'],
                          size: 45.sp,
                          color: Colors.white,
                        ),
                      SizedBox(height: 6.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            moodData['label'],
                            style: TextStyle(
                              fontSize: 13.sp,
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
            SizedBox(height: 24.h),
            _buildStatsCard(),
          ],
        ],
      ),
    );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Time Range Filter Dropdown
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeRange,
                isExpanded: true,
                isDense: false,
                menuMaxHeight: 300.h,
                alignment: AlignmentDirectional.centerStart,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A4B80),
                ),
                icon: Icon(Icons.arrow_drop_down,
                    color: const Color(0xFF0A4B80), size: 24.sp),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 'month', child: Text('Last 30 Days')),
                  DropdownMenuItem(
                      value: '3months', child: Text('Last 3 Months')),
                  DropdownMenuItem(value: 'all', child: Text('All Time')),
                ],
                onChanged: (value) {
                  setState(() {
                    _timeRange = value!;
                    _isLoadingHistory = true;
                  });
                  _loadMoodHistory();
                },
              ),
            ),
          ),
        ),

        Expanded(
          child: _isLoadingHistory
              ? ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: SkeletonLoader.card(height: 100.h),
                  ),
                )
              : _moodHistory.isEmpty
                  ? _buildEmptyHistoryState()
                  : _buildHistoryList(),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mood_outlined,
            size: 80.sp,
            color: Colors.white.withOpacity(0.6),
          ),
          SizedBox(height: 16.h),
          Text(
            'No mood logs yet',
            style: TextStyle(
              fontSize: 20.sp,
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
          SizedBox(height: 8.h),
          Text(
            'Start tracking your moods!',
            style: TextStyle(
              fontSize: 16.sp,
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

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF5CACEE),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(24.0.w),
        itemCount: _moodHistory.length,
        itemBuilder: (context, index) {
          final mood = _moodHistory[index];
          final moodType = mood['mood'] as String;

          final provider = context.read<CharacterProvider>();
          final moods = _getMoods(provider.characterGender, provider.characterNumber);
          final moodData = moods[moodType];
          
          final note = mood['note'];
          final loggedAt = DateTime.parse(mood['logged_at']);

          // Get GIF path for this mood based on character selection
          final gifPath = moodData?['gifPath'] as String?;
          final moodId = mood['id'];

          return Dismissible(
            key: Key('mood_$moodId'),
            background: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16.r),
              ),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.w),
              child: Icon(Icons.delete, color: Colors.white, size: 32.sp),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Mood Log?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              try {
                await _apiService.deleteMoodLog(moodId);
                // Clear cache to force reload
                await CacheService().remove('mood_history_$_timeRange');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mood log deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                  // Reload to restore the item
                  _loadMoodHistory();
                }
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
                border: Border.all(
                  color:
                      (moodData?['color'] as Color?)?.withOpacity(0.3) ??
                          Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  // Character GIF or fallback icon
                  if (gifPath != null)
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (moodData?['color'] as Color?) ?? Colors.grey,
                          width: 2.w,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: ImageCacheManager().buildCachedImage(
                          assetPath: gifPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: (moodData?['color'] as Color?)
                                ?.withOpacity(0.1) ??
                            Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: (moodData?['color'] as Color?)
                                  ?.withOpacity(0.5) ??
                              Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Icon(
                        moodData?['icon'] ?? Icons.mood,
                        color: moodData?['color'] ?? Colors.grey,
                        size: 32.sp,
                      ),
                    ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                moodData?['label'] ?? moodType,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0A4B80),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _formatDate(loggedAt),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(
                                    0xFF0A4B80), // Darker for better contrast
                              ),
                            ),
                          ],
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            note,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(
                                  0xFF0A4B80), // Darker for better contrast
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

    // Access provider to get mood colors
    final provider = context.read<CharacterProvider>();
    final moods = _getMoods(provider.characterGender, provider.characterNumber);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border:
            Border.all(color: const Color(0xFF5CACEE).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A4B80),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '$totalEntries mood logs',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF0A4B80), // Darker for better contrast
            ),
          ),
          SizedBox(height: 16.h),
          ...distribution.entries.map((entry) {
            final mood = entry.key;
            final count = entry.value;
            final percentage = totalEntries > 0 ? (count / totalEntries) : 0.0;
            final moodData = moods[mood];

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        moodData?['label'] ?? mood,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: moodData?['color'] ?? const Color(0xFF0A4B80),
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              const Color(0xFF0A4B80), // Darker for better contrast
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        moodData?['color'] ?? const Color(0xFF5CACEE),
                      ),
                      minHeight: 8.h,
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
