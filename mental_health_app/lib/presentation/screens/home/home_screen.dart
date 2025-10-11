// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  String userName = "Loading...";
  int userLevel = 1;
  int currentXP = 0;
  int xpToNextLevel = 100;
  String moodState = "neutral";
  String characterName = "Buddy";
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> suggestions = [];
  int completedTodos = 0;
  int currentStreak = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all data from backend
      final user = await _apiService.getCurrentUser();
      final character = await _apiService.getCharacterMoodState();
      final todoList = await _apiService.getTodos(limit: 5);
      final streakData = await _apiService.getStreak();
      
      setState(() {
        userName = user['first_name'];
        userLevel = user['level'] ?? 1;
        currentXP = user['xp'] ?? 0;
        xpToNextLevel = (userLevel * 100);
        characterName = character['character_name'] ?? "Buddy";
        moodState = character['character_state'] ?? "neutral";
        todos = List<Map<String, dynamic>>.from(todoList);
        completedTodos = todos.where((t) => t['is_completed'] == true).length;
        currentStreak = streakData['current_streak'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      // Use mock data if backend fails
      setState(() {
        userName = "Alex";
        userLevel = 5;
        currentXP = 350;
        xpToNextLevel = 500;
        moodState = "content";
        characterName = "Buddy";
        todos = [
          {"id": 1, "task_text": "Morning meditation", "is_completed": false},
          {"id": 2, "task_text": "Write journal entry", "is_completed": true},
          {"id": 3, "task_text": "Evening walk", "is_completed": false},
        ];
        completedTodos = 1;
        currentStreak = 3;
        _isLoading = false;
      });
      
      print('Error loading data: $e');
    }
  }
  
  Future<void> _toggleTodo(int index) async {
    final todo = todos[index];
    final todoId = todo['id'];
    final wasCompleted = todo['is_completed'];
    
    setState(() {
      todos[index]['is_completed'] = !wasCompleted;
      completedTodos = todos.where((t) => t['is_completed'] == true).length;
    });
    
    try {
      if (!wasCompleted) {
        await _apiService.completeTodo(todoId);
        // Refresh user data to get updated XP
        final user = await _apiService.getCurrentUser();
        setState(() {
          currentXP = user['xp'] ?? currentXP;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task completed! +10 XP 🎉'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      setState(() {
        todos[index]['is_completed'] = wasCompleted;
        completedTodos = todos.where((t) => t['is_completed'] == true).length;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
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
                  _buildCharacterCard(),
                  const SizedBox(height: 24),
                  _buildProgressTracker(),
                  const SizedBox(height: 24),
                  _buildTodoList(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, $userName! 👋",
          style: Theme.of(context).textTheme.displayMedium,
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          "How are you feeling today?",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }
  
  Widget _buildCharacterCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.medium,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Character Avatar (left side)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getMoodGradient(moodState),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.pets,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          // Character Info (right side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  characterName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMoodColor(moodState).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    moodState.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getMoodColor(moodState),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Level
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Level $userLevel",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // XP Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "XP",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          "$currentXP / $xpToNextLevel",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentXP / xpToNextLevel,
                        minHeight: 8,
                        backgroundColor: AppColors.backgroundEnd,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(delay: 200.ms, duration: 400.ms);
  }
  
  Widget _buildProgressTracker() {
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
            children: [
              const Icon(
                Icons.track_changes,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Progress",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildProgressItem(
                icon: Icons.check_circle_outline,
                label: "Tasks Done",
                value: "$completedTodos/${todos.length}",
                color: AppColors.secondary,
              ),
              const SizedBox(width: 16),
              _buildProgressItem(
                icon: Icons.local_fire_department,
                label: "Streak",
                value: "$currentStreak days",
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(delay: 300.ms, duration: 400.ms);
  }
  
  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodoList() {
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
              const Row(
                children: [
                  Icon(
                    Icons.format_list_bulleted,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: AppColors.primary,
                onPressed: () {
                  // TODO: Navigate to add task
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (todos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No tasks yet. Add one to get started!",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...todos.asMap().entries.map((entry) {
              final index = entry.key;
              final todo = entry.value;
              return _buildTodoItem(todo, index);
            }).toList(),
        ],
      ),
    ).animate().slideY(delay: 400.ms, duration: 400.ms);
  }
  
  Widget _buildTodoItem(Map<String, dynamic> todo, int index) {
    final isCompleted = todo['is_completed'] == true;
    final taskText = todo['task_text'] ?? todo['task'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (_) => _toggleTodo(index),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Expanded(
            child: Text(
              taskText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: isCompleted 
                  ? TextDecoration.lineThrough 
                  : null,
                color: isCompleted
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
              ),
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "+10 XP",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
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
          const Row(
            children: [
              Icon(
                Icons.flash_on,
                color: AppColors.accentGold,
              ),
              SizedBox(width: 8),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.mood,
                  label: "Log Mood",
                  color: AppColors.moodHappy,
                  onTap: () {
                    // TODO: Navigate to mood logging
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.book,
                  label: "Journal",
                  color: AppColors.secondary,
                  onTap: () {
                    // TODO: Navigate to journal
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(delay: 500.ms, duration: 400.ms);
  }
  
  List<Color> _getMoodGradient(String mood) {
    switch (mood.toLowerCase()) {
      case 'thriving':
        return [AppColors.moodHappy, AppColors.accentGold];
      case 'content':
        return [AppColors.moodCalm, AppColors.secondary];
      case 'struggling':
        return [AppColors.moodSad, AppColors.primary];
      case 'needs_support':
        return [AppColors.moodAnxious, AppColors.error];
      default:
        return [AppColors.primary, AppColors.primaryLight];
    }
  }
  
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'thriving':
        return AppColors.moodHappy;
      case 'content':
        return AppColors.moodCalm;
      case 'struggling':
        return AppColors.moodSad;
      case 'needs_support':
        return AppColors.moodAnxious;
      default:
        return AppColors.primary;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}