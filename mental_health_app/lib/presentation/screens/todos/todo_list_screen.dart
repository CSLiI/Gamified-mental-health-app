import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import '../../widgets/quest_card.dart';
import '../../../core/utils/debouncer.dart';
import '../../widgets/level_up_dialog.dart';

class TodoListScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const TodoListScreen({super.key, this.selectedDate});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _taskController = TextEditingController();
  late TabController _tabController;
  late DateTime _currentDate;

  bool _isLoading = false;
  bool _isLoadingQuests = false;
  List<dynamic> _todos = [];
  List<Map<String, dynamic>> _dailyQuests = [];
  List<Map<String, dynamic>> _weeklyQuests = [];
  final Debouncer _actionDebouncer =
      Debouncer(duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate ?? DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes to update FloatingActionButton
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTodos(),
      _loadQuests(),
    ]);
  }

  Future<void> _loadQuests() async {
    setState(() => _isLoadingQuests = true);

    try {
      // Ensure quests exist
      await _apiService.generateDailyQuests();
      await _apiService.generateWeeklyQuests();

      final result = await _apiService.getActiveQuests();

      if (mounted) {
        setState(() {
          _dailyQuests =
              List<Map<String, dynamic>>.from(result['daily_quests'] ?? []);
          _weeklyQuests =
              List<Map<String, dynamic>>.from(result['weekly_quests'] ?? []);
          _isLoadingQuests = false;
        });
      }
    } catch (e) {
      print('Error loading quests: $e');
      if (mounted) {
        setState(() => _isLoadingQuests = false);
      }
    }
  }

  Future<void> _loadTodos() async {
    try {
      // Check cache first
      final cachedTodos = await CacheService().get<List<dynamic>>(
        'todos_daily',
        maxAge: CacheService.shortCache,
      );

      if (cachedTodos != null && mounted) {
        setState(() {
          // Filter for the selected date
          _todos = cachedTodos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']).toLocal();
            return createdAt.year == _currentDate.year &&
                createdAt.month == _currentDate.month &&
                createdAt.day == _currentDate.day;
          }).toList();
        });
      }

      // Fetch fresh data in background
      final todos = await _apiService.getTodos(limit: 500, periodType: 'daily');

      // Update cache
      await CacheService().set('todos_daily', todos);

      if (mounted) {
        setState(() {
          // Filter for the selected date
          _todos = todos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']).toLocal();
            return createdAt.year == _currentDate.year &&
                createdAt.month == _currentDate.month &&
                createdAt.day == _currentDate.day;
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading todos: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showAddTaskDialog(String category) async {
    _taskController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Task for ${_formatDate(_currentDate)}',
          style: const TextStyle(
            color: Color(0xFF0A4B80),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(
            hintText: 'Enter task description...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5CACEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5CACEE), width: 2),
            ),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _taskController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addTodo(_currentDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5CACEE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                const Text('Add Task', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addTodo(DateTime selectedDate) async {
    if (_taskController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create datetime at noon local time for the selected day
      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        12,
        0,
        0,
      );

      await _apiService.createTodo({
        'task_text': _taskController.text.trim(),
        'is_completed': false,
        'period_type': 'daily',
        'created_at': selectedDateTime.toUtc().toIso8601String(),
      });

      _taskController.clear();

      if (!mounted) return;

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added successfully!'),
          backgroundColor: Color(0xFF28A745),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task: ${e.toString()}'),
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

  Future<void> _toggleTodo(int todoId, bool isCompleted) async {
    setState(() {
      final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
      if (todoIndex != -1) {
        _todos[todoIndex]['is_completed'] = !isCompleted;
      }
    });

    try {
      if (!isCompleted) {
        await _apiService.completeTodo(todoId);
        _apiService.checkAchievements();

        // Update quest progress for general category
        await _apiService.updateQuestProgress('general', increment: 1);

        // Reload quests to show updated progress
        await _loadQuests();

        // Check if leveled up from quest XP
        await _checkLevelUp();
      } else {
        await _apiService.uncompleteTodo(todoId);
      }
      await _loadData();
    } catch (e) {
      setState(() {
        final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
        if (todoIndex != -1) {
          _todos[todoIndex]['is_completed'] = isCompleted;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteTodo(int todoId) async {
    try {
      await _apiService.deleteTodo(todoId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task deleted'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _generateQuests() async {
    // Prevent rapid duplicate taps
    _actionDebouncer.run(() async {
      // Show loading state
      if (mounted) {
        setState(() => _isLoadingQuests = true);
      }

      try {
        // Clear old quests before generating new ones
        if (mounted) {
          setState(() {
            _dailyQuests = [];
            _weeklyQuests = [];
          });
        }

        // Generate new quests
        await _apiService.generateDailyQuests();
        await _apiService.generateWeeklyQuests();

        // Force fresh load (no cache)
        await _loadQuests();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ New quests generated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingQuests = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate quests: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
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
            petsUnlocked:
                List<Map<String, dynamic>>.from(result['pets_unlocked'] ?? []),
          ),
        );
      }
    } catch (e) {
      print('Error checking level up: $e');
    }
  }

  Widget _buildQuestList(List<Map<String, dynamic>> quests, String type) {
    if (_isLoadingQuests && quests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadQuests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${type == 'daily' ? 'Daily' : 'Weekly'} Quests',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap ✨ to generate new quests',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quests.length,
        itemBuilder: (context, index) {
          final quest = quests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuestCard(
              key: ValueKey('${type}_${quest['id'] ?? quest['task']}'),
              task: quest['task'],
              category: quest['category'] ?? 'general',
              difficulty: quest['difficulty'] ?? 'medium',
              xpReward: quest['xp_reward'],
              progressCurrent: quest['progress_current'] ?? 0,
              progressTotal: quest['progress_total'] ?? 1,
              isCompleted: quest['is_completed'] ?? false,
              questType: type,
              expiresAt: DateTime.parse(quest['expires_at']),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A4B80)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tasks & Quests',
          style: TextStyle(
            color: Color(0xFF0A4B80),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Daily Quests'),
            Tab(text: 'Weekly Quests'),
            Tab(text: 'My Todos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestList(_dailyQuests, 'daily'),
          _buildQuestList(_weeklyQuests, 'weekly'),
          _buildTaskList('Daily', _todos),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTaskDialog('Daily'),
              backgroundColor: const Color(0xFF5CACEE),
              icon: const Icon(Icons.add, color: Colors.white),
              label:
                  const Text('New Task', style: TextStyle(color: Colors.white)),
            )
          : FloatingActionButton(
              onPressed: _generateQuests,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
    );
  }

  Widget _buildTaskList(String category, List<dynamic> tasks) {
    if (_isLoading && tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CACEE)),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $category Tasks',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Stats header
            final completed =
                tasks.where((t) => t['is_completed'] == true).length;
            final total = tasks.length;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', total.toString(), Icons.list_alt),
                  _buildStatItem(
                      'Done', completed.toString(), Icons.check_circle),
                  _buildStatItem('Pending', (total - completed).toString(),
                      Icons.schedule),
                ],
              ),
            );
          }

          final todo = tasks[index - 1];
          final isCompleted = todo['is_completed'] ?? false;
          final createdAt = DateTime.parse(todo['created_at']).toLocal();

          return Dismissible(
            key: Key(todo['id'].toString()),
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteTodo(todo['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey[100] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.grey[300]!
                      : const Color(0xFF5CACEE).withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () => _toggleTodo(todo['id'], isCompleted),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success
                            : const Color(0xFF5CACEE),
                        width: 2,
                      ),
                      color:
                          isCompleted ? AppColors.success : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                title: Text(
                  todo['task_text'],
                  style: TextStyle(
                    color: const Color(0xFF0A4B80),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '+10 XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  onPressed: () => _deleteTodo(todo['id']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF5CACEE), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A4B80),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
