// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> interests = [];
  Map<String, dynamic> stats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final [user, achievementsList, interestsList, todoStats, moodStats, streak] = await Future.wait([
        _apiService.getUserProfile(),
        _apiService.getUserAchievements(),
        _apiService.getUserInterests(),
        _apiService.getTodoStatistics(),
        _apiService.getMoodStatistics(),
        _apiService.getStreak(),
      ]);
      
      setState(() {
        userData = Map<String, dynamic>.from(user as Map);
        achievements = List<Map<String, dynamic>>.from(achievementsList as List);
        interests = List<Map<String, dynamic>>.from(interestsList as List);
        stats = {
          'total_moods': (moodStats as Map)['total_entries'] ?? 0,
          'total_journals': 0, // Will be loaded separately
          'current_streak': (streak as Map)['current_streak'] ?? 0,
          'tasks_completed': (todoStats as Map)['completed_tasks'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      // Use mock data on error
      setState(() {
        userData = {
          "first_name": "Alex",
          "last_name": "Chen",
          "email": "alex@example.com",
          "level": 5,
          "xp": 350,
          "created_at": "2024-09-01",
        };
        
        achievements = [
          {
            "achievement": {
              "name": "First Steps",
              "description": "Log your first mood",
              "xp_reward": 10,
            },
            "is_claimed": true,
          },
          {
            "achievement": {
              "name": "Week Warrior",
              "description": "Maintain a 7-day streak",
              "xp_reward": 50,
            },
            "is_claimed": true,
          },
        ];
        
        interests = [
          {"name": "Gaming"},
          {"name": "Reading"},
          {"name": "Music"},
          {"name": "Meditation"},
        ];
        
        stats = {
          "total_moods": 45,
          "total_journals": 12,
          "current_streak": 7,
          "tasks_completed": 28,
        };
        
        _isLoading = false;
      });
      
      print('Error loading profile: $e');
    }
  }
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _apiService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildAchievementsSection(),
                const SizedBox(height: 24),
                _buildInterestsSection(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Profile",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Navigate to settings
          },
          icon: const Icon(Icons.settings),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
  
  Widget _buildProfileCard() {
    final firstName = userData['first_name'] ?? 'A';
    final lastName = userData['last_name'] ?? 'C';
    final initials = '${firstName[0]}${lastName[0]}'.toUpperCase();
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.large,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            "${userData['first_name']} ${userData['last_name']}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userData['email'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // Level & XP
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Level ${userData['level'] ?? 1} • ${userData['xp'] ?? 0} XP",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Member since
          Text(
            "Member since ${_formatDate(userData['created_at'])}",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().slideY(delay: 100.ms, duration: 400.ms);
  }
  
  Widget _buildStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.small,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Stats",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.mood,
                label: "Moods Logged",
                value: stats['total_moods'].toString(),
                color: AppColors.moodHappy,
              ),
              _buildStatCard(
                icon: Icons.auto_stories,
                label: "Journal Entries",
                value: stats['total_journals'].toString(),
                color: AppColors.secondary,
              ),
              _buildStatCard(
                icon: Icons.local_fire_department,
                label: "Current Streak",
                value: "${stats['current_streak']} days",
                color: AppColors.warning,
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                label: "Tasks Done",
                value: stats['tasks_completed'].toString(),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(delay: 200.ms, duration: 400.ms);
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementsSection() {
    final displayAchievements = achievements.take(3).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.small,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Achievements",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all achievements
                },
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayAchievements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No achievements yet. Keep going!",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...displayAchievements.map((achievement) {
              return _buildAchievementItem(achievement);
            }).toList(),
        ],
      ),
    ).animate().slideY(delay: 300.ms, duration: 400.ms);
  }
  
  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final achievementData = achievement['achievement'] ?? {};
    final isUnlocked = achievement['is_claimed'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGold.withValues(alpha: 0.2),
                  AppColors.accentMint.withValues(alpha: 0.2),
                ],
              )
            : null,
        color: isUnlocked ? null : AppColors.backgroundEnd,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? AppColors.accentGold.withValues(alpha: 0.3)
              : AppColors.textTertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.accentGold.withValues(alpha: 0.3)
                  : AppColors.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: isUnlocked ? AppColors.accentGold : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievementData['name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked 
                              ? AppColors.textPrimary 
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    if (isUnlocked && achievementData['xp_reward'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "+${achievementData['xp_reward']} XP",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  achievementData['description'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked 
                        ? AppColors.textSecondary 
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInterestsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.small,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Interests",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // TODO: Add new interest
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (interests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No interests added yet",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return _buildInterestChip(interest);
              }).toList(),
            ),
        ],
      ),
    ).animate().slideY(delay: 400.ms, duration: 400.ms);
  }
  
  Widget _buildInterestChip(Map<String, dynamic> interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.2),
            AppColors.secondaryLight.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            interest['name'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.edit,
            title: "Edit Profile",
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.notifications,
            title: "Notifications",
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.palette,
            title: "Appearance",
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingItem(
            icon: Icons.logout,
            title: "Logout",
            textColor: AppColors.error,
            onTap: _logout,
          ),
        ],
      ),
    ).animate().slideY(delay: 500.ms, duration: 400.ms);
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor ?? AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return "";
    }
  }
}