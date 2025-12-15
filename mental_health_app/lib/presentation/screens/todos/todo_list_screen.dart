import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import '../../widgets/quest_card.dart';
import '../../../core/utils/debouncer.dart';
import '../../widgets/level_up_dialog.dart';
import '../../widgets/pet_companion_widget.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_provider.dart';

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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate ?? DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes to update FloatingActionButton
    _tabController.addListener(() {
      setState(() {});
    });
    // Fast load: show cached immediately, then background refresh
    _loadCachedDataFirst();
    
    // Refresh user data to get latest energy when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).refreshUser();
      }
    });
  }
  
  @override
  void didUpdateWidget(TodoListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh user data whenever widget updates (e.g., navigating back to this screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).refreshUser();
      }
    });
  }

  /// Display cached data instantly, then refresh in background
  Future<void> _loadCachedDataFirst() async {
    // 1) Try to show cached todos immediately (no await on cache read)
    CacheService()
        .get<List<dynamic>>(
      'todos_daily',
      maxAge: const Duration(minutes: 30),
    )
        .then((cachedTodos) {
      if (cachedTodos != null && mounted) {
        setState(() {
          _todos = cachedTodos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']).toLocal();
            return createdAt.year == _currentDate.year &&
                createdAt.month == _currentDate.month &&
                createdAt.day == _currentDate.day;
          }).toList()
            ..sort((a, b) {
              final aCompleted = a['is_completed'] ?? false;
              final bCompleted = b['is_completed'] ?? false;
              if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
              return (b['id'] as int).compareTo(a['id'] as int);
            });
        });
      }
    });

    // 2) Refresh fresh data in background (parallel)
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
    if (!mounted) return;
    setState(() => _isLoadingQuests = true);

    try {
      // Parallel: generate quests if needed and fetch active quests
      final results = await Future.wait([
        _apiService.generateDailyQuests(),
        _apiService.generateWeeklyQuests(),
        _apiService.getActiveQuests(),
      ]);

      final result = results[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          // Backend returns 'daily' and 'weekly' keys (not 'daily_quests'/'weekly_quests')
          _dailyQuests = List<Map<String, dynamic>>.from(result['daily'] ?? []);
          _weeklyQuests =
              List<Map<String, dynamic>>.from(result['weekly'] ?? []);
          _isLoadingQuests = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading quests: $e');
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
          }).toList()
            ..sort((a, b) {
              final aCompleted = a['is_completed'] ?? false;
              final bCompleted = b['is_completed'] ?? false;
              if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
              return (b['id'] as int).compareTo(a['id'] as int);
            });
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
          }).toList()
            ..sort((a, b) {
              final aCompleted = a['is_completed'] ?? false;
              final bCompleted = b['is_completed'] ?? false;
              if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
              return (b['id'] as int).compareTo(a['id'] as int);
            });
        });
      }
    } catch (e) {
      // print('Error loading todos: $e');
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Task for ${_formatDate(_currentDate)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: 'Enter task description...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF6B9080), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      maxLines: 3,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _taskController.clear();
                          Navigator.pop(context);
                        },
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _addTodo(_currentDate);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B9080),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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

  Future<void> _addTodo(DateTime selectedDate) async {
    if (_taskController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use current time if selected date is today, otherwise use noon
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      final selectedDateTime = isToday
          ? now
          : DateTime(
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
    if (mounted) {
      setState(() {
        final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
        if (todoIndex != -1) {
          _todos[todoIndex]['is_completed'] = !isCompleted;
        }
      });
    }

    try {
      if (!isCompleted) {
        final result = await _apiService.completeTodo(todoId);
        _apiService.checkAchievements();

        // Update quest progress for general category
        await _apiService.updateQuestProgress('general', increment: 1);

        // Reload quests to show updated progress
        await _loadQuests();

        // Check if leveled up from quest XP
        await _checkLevelUp();
        
        // Refresh user data to update energy display
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).refreshUserAfterAction();
        }
        
        // Show success message with XP and energy
        if (mounted) {
          // SnackBar removed for cleaner UI
        }
      } else {
        final result = await _apiService.uncompleteTodo(todoId);
        
        // Refresh user data to update energy display
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).refreshUserAfterAction();
        }
        
        if (mounted) {
          // SnackBar removed for cleaner UI
        }
      }
      // Delay the re-sorting to allow user to see the checkmark animation, then move it
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        setState(() {
          _todos.sort((a, b) {
            final aCompleted = a['is_completed'] ?? false;
            final bCompleted = b['is_completed'] ?? false;
            if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
            return (b['id'] as int).compareTo(a['id'] as int);
          });
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
          if (todoIndex != -1) {
            _todos[todoIndex]['is_completed'] = isCompleted;
          }
        });
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
        // SnackBar removed for cleaner UI
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
      // 1. Check if we already have daily quests
      if (_dailyQuests.isNotEmpty) {
        final shouldReroll = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reroll Daily Quests?'),
            content: const Text(
                'This will replace your current daily quests with new ones.\n\nQuests you have already claimed rewards for will be kept.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reroll'),
              ),
            ],
          ),
        );

        if (shouldReroll != true) return;
      }

      // Show loading state
      if (mounted) {
        setState(() => _isLoadingQuests = true);
      }

      try {
        // Clear old quests before generating new ones (visual feedback)
        if (mounted) {
          setState(() {
            _dailyQuests = [];
            // We don't clear weekly quests as we aren't rerolling them yet
            // _weeklyQuests = [];
          });
        }

        // Generate new quests (force refresh if we had quests before)
        await _apiService.generateDailyQuests(forceRefresh: true);
        // Only generate weekly if strict needed, but usually safe to call
        await _apiService.generateWeeklyQuests();

        // Force fresh load (no cache)
        await _loadQuests();

        if (mounted) {
          // Refresh user data to update energy if reroll cost energy
          await Provider.of<UserProvider>(context, listen: false).refreshUser();
          
          // SnackBar removed for cleaner UI
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
      debugPrint('Level check result: $result');

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
      debugPrint('Error checking level up: $e');
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
          final questId = quest['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuestCard(
              key: ValueKey('${type}_${quest['id'] ?? quest['task']}'),
              questId: questId,
              task: quest['task'],
              category: quest['category'] ?? 'general',
              difficulty: quest['difficulty'] ?? 'medium',
              xpReward: quest['xp_reward'],
              progressCurrent: quest['progress_current'] ?? 0,
              progressTotal: quest['progress_total'] ?? 1,
              isCompleted: quest['is_completed'] ?? false,
              questType: type,
              expiresAt: DateTime.parse(quest['expires_at']),
              onManualComplete: questId != null
                  ? () => _manuallyCompleteQuest(questId, quest['task'])
                  : null,
              onIncrementProgress: questId != null
                  ? (amount) => _incrementQuestProgress(questId, amount)
                  : null,
              rewardClaimed: quest['reward_claimed'] ?? false,
            ),
          );
        },
      ),
    );
  }

  // Manually complete a quest
  Future<void> _manuallyCompleteQuest(int questId, String taskName) async {
    try {
      final result = await _apiService.completeQuest(questId);

      if (mounted) {
        // SnackBar removed for cleaner UI
      }

      // Reload quests and check for level up
      await _loadQuests();
      await _checkLevelUp();
      
      // Refresh user data to update energy display
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).refreshUserAfterAction();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete quest: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _incrementQuestProgress(int questId, int amount) async {
    try {
      final result = await _apiService.incrementQuestProgress(questId, amount: amount);
      
      if (result['success'] == true) {
        final isNowComplete = result['is_completed'] == true;
        final xpEarned = result['xp_earned'] ?? 0;
        final energyEarned = result['energy_earned'] ?? 0;

        if (mounted) {
          // SnackBar removed for cleaner UI
        }

        await _loadQuests();
        
        // Refresh user data to update energy display after any progress change
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).refreshUser();
        }
        
        if (isNowComplete) {
          await _checkLevelUp();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to UserProvider for energy updates
    final userProvider = Provider.of<UserProvider>(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Tasks & Quests',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: themeProvider.primaryColor,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: themeProvider.primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList('Daily', _todos),
                _buildQuestList(_dailyQuests, 'daily'),
                _buildQuestList(_weeklyQuests, 'weekly'),
              ],
            ),
            floatingActionButton: _tabController.index == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _showAddTaskDialog('Daily'),
                    backgroundColor: themeProvider.primaryColor,
                    elevation: 4,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'New Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : FloatingActionButton(
                    onPressed: _generateQuests,
                    backgroundColor: themeProvider.primaryColor,
                    elevation: 4,
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList(String category, List<dynamic> tasks) {
    if (_isLoading && tasks.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No tasks for today',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a small step forward',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    // Use tasks directly (already sorted by _loadTodos)
    final sortedTasks = tasks;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedTasks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Stats header
            final completed =
                sortedTasks.where((t) => t['is_completed'] == true).length;
            final total = sortedTasks.length;
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Total', total.toString(), Icons.list_alt_rounded),
                  Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                  _buildStatItem('Done', completed.toString(),
                      Icons.check_circle_outline_rounded),
                  Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                  _buildStatItem('Left', (total - completed).toString(),
                      Icons.hourglass_empty_rounded),
                ],
              ),
            );
          }

          // Ensure index is valid for sortedTasks
          if (index - 1 >= sortedTasks.length) return const SizedBox.shrink();

          final todo = sortedTasks[index - 1];
          return _buildTodoItem(todo);
        },
      ),
    );
  }

  Widget _buildTodoItem(dynamic todo) {
    final isCompleted = todo['is_completed'] ?? false;
    final createdAt = DateTime.parse(todo['created_at']).toLocal();

    return Dismissible(
        key: Key('todo_${todo['id']}'),
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF5350).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFFEF5350)),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Delete from API first, then confirm dismiss
          try {
            await _apiService.deleteTodo(todo['id']);
            if (mounted) {
              // SnackBar removed for cleaner UI
            }
            return true; // Allow dismiss animation
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error),
              );
            }
            return false; // Cancel dismiss
          }
        },
        onDismissed: (_) {
          // Remove from local list after successful delete
          setState(() {
            _todos.removeWhere((t) => t['id'] == todo['id']);
          });
        },
        child: InkWell(
          onTap: () => _toggleTodo(todo['id'], isCompleted),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).disabledColor.withOpacity(0.1)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo['task_text'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.grey
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5)),
                              ),
                              if (!isCompleted) ...[
                                if (!(todo['reward_claimed'] ?? false)) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.amber.withOpacity(0.3),
                                          width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded,
                                            size: 10, color: Colors.amber[800]),
                                        const SizedBox(width: 2),
                                        Text(
                                          '5',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    '+10 XP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Builder(builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500),
          ),
        ],
      );
    });
  }
}
