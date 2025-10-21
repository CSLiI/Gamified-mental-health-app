import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _taskController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = false;
  bool _isLoadingTodos = true;
  List<dynamic> _todos = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _loadStats(),
    ]);
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _apiService.getTodos(limit: 100);
      setState(() {
        _todos = todos;
        _isLoadingTodos = false;
      });
    } catch (e) {
      setState(() => _isLoadingTodos = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.getTodoStatistics();
      setState(() => _stats = stats);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _addTodo() async {
    if (_taskController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.createTodo({
        'task_text': _taskController.text.trim(),
        'is_completed': false,
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
    // Optimistic update - update UI immediately
    setState(() {
      final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
      if (todoIndex != -1) {
        _todos[todoIndex]['is_completed'] = !isCompleted;
        if (!isCompleted) {
          _todos[todoIndex]['completed_at'] = DateTime.now().toIso8601String();
        } else {
          _todos[todoIndex]['completed_at'] = null;
        }
      }
    });

    try {
      if (!isCompleted) {
        // Completing the todo
        await _apiService.completeTodo(todoId);

        if (!mounted) return;

        // Check achievements silently
        _apiService.checkAchievements();
      } else {
        // Uncompleting - mark as incomplete
        await _apiService.updateTodo(todoId, {
          'task_text': _todos.firstWhere((t) => t['id'] == todoId)['task_text'],
          'is_completed': false,
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        final todoIndex = _todos.indexWhere((t) => t['id'] == todoId);
        if (todoIndex != -1) {
          _todos[todoIndex]['is_completed'] = isCompleted;
          if (isCompleted) {
            _todos[todoIndex]['completed_at'] =
                DateTime.now().toIso8601String();
          } else {
            _todos[todoIndex]['completed_at'] = null;
          }
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteTodo(int todoId) async {
    try {
      await _apiService.deleteTodo(todoId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted'),
          backgroundColor: AppColors.info,
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
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
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced contrast header text with shadow for better visibility
                    const Text(
                      'My Tasks',
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
                    const SizedBox(height: 8),
                    const Text(
                      'Complete tasks to earn XP',
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

                    // Stats Card
                    if (_stats != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total',
                              _stats!['total_tasks'].toString(),
                              Icons.list_alt,
                            ),
                            _buildStatItem(
                              'Completed',
                              _stats!['completed_tasks'].toString(),
                              Icons.check_circle_outline,
                            ),
                            _buildStatItem(
                              'Pending',
                              _stats!['pending_tasks'].toString(),
                              Icons.schedule,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Add Task Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          decoration: const InputDecoration(
                            hintText: 'Add a new task...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(
                                0xFF0A4B80), // Darker blue for better contrast
                            fontSize: 16,
                          ),
                          onSubmitted: (_) => _addTodo(),
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : _addTodo,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF5CACEE)),
                                ),
                              )
                            : const Icon(
                                Icons.add_circle,
                                color: Color(0xFF5CACEE),
                                size: 32,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tab Bar - with improved spacing and contrast
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF5CACEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(
                      0xFF0A4B80), // Darker color for better contrast
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8), // More padding
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Text(
                      'All',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Active',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Done',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Task List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(null),
                    _buildTaskList(false),
                    _buildTaskList(true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5CACEE), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A4B80), // Darker blue for better contrast
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54, // Darker for better contrast
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(bool? completed) {
    if (_isLoadingTodos) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ));
    }

    final filteredTodos = completed == null
        ? _todos
        : _todos.where((todo) => todo['is_completed'] == completed).toList();

    if (filteredTodos.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed == true
                    ? Icons.check_circle_outline
                    : Icons.assignment_outlined,
                size: 64,
                color: Colors.white.withAlpha(150), // Better contrast
              ),
              const SizedBox(height: 16),
              Text(
                completed == true ? 'No completed tasks yet' : 'No tasks yet',
                style: const TextStyle(
                  fontSize: 18,
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
                'Add a task to get started!',
                style: TextStyle(
                  fontSize: 14,
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF5CACEE),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          final isCompleted = todo['is_completed'] ?? false;
          final taskText = todo['task_text'] ?? '';
          final createdAt = DateTime.parse(todo['created_at']);

          return Dismissible(
            key: Key(todo['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            onDismissed: (direction) {
              _deleteTodo(todo['id']);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                  onTap: () {
                    _toggleTodo(todo['id'], isCompleted);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(
                                      0xFF28A745) // Success green with better contrast
                                  : const Color(0xFF5CACEE),
                              width: 2,
                            ),
                            color: isCompleted
                                ? const Color(0xFF28A745) // Success green
                                : Colors.transparent,
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taskText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isCompleted
                                      ? Colors.black54 // Better contrast
                                      : const Color(0xFF0A4B80), // Darker blue
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54, // Better contrast
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5CACEE).withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+10 XP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5CACEE),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
