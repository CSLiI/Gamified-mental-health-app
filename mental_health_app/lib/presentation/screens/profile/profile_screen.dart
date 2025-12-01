import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/dio_client.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/utils/image_cache_manager.dart';
import '../../../core/utils/debouncer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _dioClient = DioClient();
  final Debouncer _actionDebouncer = Debouncer(milliseconds: 350);

  Map<String, dynamic>? _userData;
  List<dynamic> _achievements = [];
  Map<String, dynamic>? _moodState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Check cache first
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'profile_data',
        maxAge: CacheService.shortCache,
      );

      if (cachedData != null && mounted) {
        setState(() {
          _userData = cachedData['user'];
          _achievements = cachedData['achievements'] ?? [];
          _moodState = cachedData['moodState'];
          _isLoading = false;
        });
      }

      // Fetch fresh data in background using Future.wait
      final results = await Future.wait([
        _apiService.getCurrentUser(),
        _apiService.getMyAchievements(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final achievements = results[1] as List<dynamic>;

      // Get character mood state if user has a character
      Map<String, dynamic>? moodState;
      if (user['character'] != null) {
        try {
          moodState = await _apiService.getCharacterMoodState();
        } catch (e) {
          print('Error loading mood state: $e');
        }
      }

      // Update cache
      await CacheService().set('profile_data', {
        'user': user,
        'achievements': achievements,
        'moodState': moodState,
      });

      if (mounted) {
        setState(() {
          _userData = user;
          _achievements = achievements;
          _moodState = moodState;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _actionDebouncer.run(() async {
        await _dioClient.logout();
        if (!mounted) return;
        context.go('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? _buildProfileSkeleton()
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF5CACEE),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      _buildStatsSection(),
                      // Removed _buildAchievementsSection() - already in progress page
                      _buildOptionsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header skeleton
          SkeletonLoader.character(size: 120),
          const SizedBox(height: 16),
          SkeletonLoader.text(width: 150, height: 20),
          const SizedBox(height: 8),
          SkeletonLoader.text(width: 200, height: 14),
          const SizedBox(height: 24),
          // Stats skeleton
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader.card(height: 80)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader.card(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          // Options skeleton
          SkeletonLoader.card(height: 60),
          const SizedBox(height: 12),
          SkeletonLoader.card(height: 60),
          const SizedBox(height: 12),
          SkeletonLoader.card(height: 60),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _userData?['first_name'] ?? 'User';
    final lastName = _userData?['last_name'] ?? '';
    final email = _userData?['email'] ?? '';
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final character = _userData?['character'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(
            0xFF6C5CE7), // Soft purple - calming and professional for mental health
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Character Avatar (square)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: character != null
                  ? _buildCharacterImage(character)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(76),
                            Colors.white.withAlpha(25),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(230),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Level $level  •  $xp XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final currentStreak = _userData?['current_streak'] ?? 0;
    final level = _userData?['level'] ?? 1;
    final xp = _userData?['xp'] ?? 0;
    final xpForNextLevel = level * 100;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Progress Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Level Progress',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xp / $xpForNextLevel XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${((xp / xpForNextLevel) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: (xp / xpForNextLevel).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: currentStreak.toString(),
                  label: 'Day Streak',
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  value: _achievements
                      .where((a) => a['is_claimed'] == true)
                      .length
                      .toString(),
                  label: 'Achievements',
                  color: const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(60),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A4B80), // Darker blue for better contrast
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A4B80), // Darker blue for better contrast
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              // Navigate to settings
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              // Show about dialog
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.error,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage(Map<String, dynamic> character) {
    final gender = character['gender'] ?? 'boy';
    final characterNumber = character['number'] ?? 1;

    // Get mood state from character mood state
    String moodState = 'Calm'; // Default to Calm (was neutral)
    if (_moodState != null && _moodState!['character_state'] != null) {
      // Map character_state to mood state for GIF filename (proper case)
      switch (_moodState!['character_state']) {
        case 'thriving':
          moodState = 'Happy';
          break;
        case 'content':
          moodState = 'Calm';
          break;
        case 'struggling':
          moodState = 'Sad';
          break;
        case 'needs_support':
          moodState = 'Angry';
          break;
        default:
          moodState = 'Calm';
      }
    }

    final genderPrefix = gender == 'female' ? 'Girl' : 'Boy';

    // Format: HappyBoy1.gif
    return ImageCacheManager().buildCachedImage(
      assetPath:
          'assets/images/${genderPrefix}_Gif_33FPS/$moodState$genderPrefix$characterNumber.gif',
      fit: BoxFit.cover,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _actionDebouncer.run(() async => onTap()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (color ?? const Color(0xFF5CACEE)).withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? const Color(0xFF5CACEE),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ??
                          const Color(
                              0xFF0A4B80), // Darker blue for better contrast
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF0A4B80), // Darker for better contrast
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
