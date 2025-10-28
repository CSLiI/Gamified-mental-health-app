import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class MonthlyGoalsScreen extends StatefulWidget {
  const MonthlyGoalsScreen({super.key});

  @override
  State<MonthlyGoalsScreen> createState() => _MonthlyGoalsScreenState();
}

class _MonthlyGoalsScreenState extends State<MonthlyGoalsScreen> {
  final _apiService = ApiService();
  final _goalController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _goals = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set to first day of current month
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadGoals();
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      // Load only 'monthly' period type tasks
      final todos =
          await _apiService.getTodos(limit: 500, periodType: 'monthly');
      if (mounted) {
        setState(() {
          // Filter by selected month
          _goals = todos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']);
            return createdAt.year == _currentMonth.year &&
                createdAt.month == _currentMonth.month;
          }).toList()
            ..sort((a, b) {
              final aCompleted = a['is_completed'] ?? false;
              final bCompleted = b['is_completed'] ?? false;
              if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
              return DateTime.parse(b['created_at'])
                  .compareTo(DateTime.parse(a['created_at']));
            });
        });
      }
    } catch (e) {
      print('Error loading goals: $e');
    }
  }

  Future<void> _addGoal() async {
    if (_goalController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Use the currently selected month
      final goalDate =
          DateTime(_currentMonth.year, _currentMonth.month, 1, 12, 0, 0);

      await _apiService.createTodo({
        'task_text': _goalController.text.trim(),
        'is_completed': false,
        'period_type': 'monthly',
        'created_at': goalDate.toUtc().toIso8601String(),
      });

      _goalController.clear();
      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Monthly goal added!'),
              backgroundColor: Color(0xFF2196F3)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleGoal(int id, bool isCompleted) async {
    setState(() {
      final index = _goals.indexWhere((g) => g['id'] == id);
      if (index != -1) _goals[index]['is_completed'] = !isCompleted;
    });

    try {
      if (!isCompleted) {
        await _apiService.completeTodo(id);
        _apiService.checkAchievements();
      } else {
        await _apiService.uncompleteTodo(id);
      }
      await _loadGoals();
    } catch (e) {
      setState(() {
        final index = _goals.indexWhere((g) => g['id'] == id);
        if (index != -1) _goals[index]['is_completed'] = isCompleted;
      });
    }
  }

  Future<void> _deleteGoal(int id) async {
    try {
      await _apiService.deleteTodo(id);
      await _loadGoals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _goals.where((g) => g['is_completed'] == true).length;
    final total = _goals.length;

    final monthName = _getMonthName(_currentMonth.month);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('📊 Monthly Goals',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 32),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month - 1, 1);
                          });
                          _loadGoals();
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final now = DateTime.now();
                            _currentMonth = DateTime(now.year, now.month, 1);
                          });
                          _loadGoals();
                        },
                        child: const Text(
                          'This Month',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white, size: 32),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month + 1, 1);
                          });
                          _loadGoals();
                        },
                      ),
                    ],
                  ),
                  Text(
                    '$monthName ${_currentMonth.year}',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBadge('Total', total.toString(), Icons.flag),
                      _buildStatBadge(
                          'Done', completed.toString(), Icons.check_circle),
                      _buildStatBadge('Left', (total - completed).toString(),
                          Icons.pending),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Goals list
          Expanded(
            child: _goals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No monthly goals yet',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Tap + to add your first goal',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGoals,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isCompleted = goal['is_completed'] ?? false;

                        return Dismissible(
                          key: Key(goal['id'].toString()),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteGoal(goal['id']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  isCompleted ? Colors.grey[100] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFF2196F3).withOpacity(0.3)),
                            ),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () =>
                                    _toggleGoal(goal['id'], isCompleted),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF2196F3),
                                        width: 2),
                                    color: isCompleted
                                        ? const Color(0xFF2196F3)
                                        : Colors.transparent,
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check,
                                          size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              title: Text(
                                goal['task_text'],
                                style: TextStyle(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteGoal(goal['id']),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Monthly Goal'),
              content: TextField(
                controller: _goalController,
                decoration:
                    const InputDecoration(hintText: 'Enter your goal...'),
                maxLines: 3,
                autofocus: true,
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addGoal();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3)),
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Goal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }
}
