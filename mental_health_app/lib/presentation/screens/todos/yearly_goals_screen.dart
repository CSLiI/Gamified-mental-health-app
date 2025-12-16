import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';

class YearlyGoalsScreen extends StatefulWidget {
  const YearlyGoalsScreen({super.key});

  @override
  State<YearlyGoalsScreen> createState() => _YearlyGoalsScreenState();
}

class _YearlyGoalsScreenState extends State<YearlyGoalsScreen> {
  final _apiService = ApiService();
  final _goalController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _goals = [];
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
    _loadGoals();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      // Check cache first
      final cachedTodos = await CacheService().get<List<dynamic>>(
        'todos_yearly',
        maxAge: CacheService.shortCache,
      );

      if (cachedTodos != null && mounted) {
        setState(() {
          // Filter by selected year
          _goals = cachedTodos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']);
            return createdAt.year == _currentYear;
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

      // Load only 'yearly' period type tasks
      final todos =
          await _apiService.getTodos(limit: 500, periodType: 'yearly');

      // Update cache
      await CacheService().set('todos_yearly', todos);

      if (mounted) {
        setState(() {
          // Filter by selected year
          _goals = todos.where((todo) {
            final createdAt = DateTime.parse(todo['created_at']);
            return createdAt.year == _currentYear;
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
      // Use the currently selected year
      final goalDate = DateTime(_currentYear, 1, 1, 12, 0, 0);

      await _apiService.createTodo({
        'task_text': _goalController.text.trim(),
        'is_completed': false,
        'period_type': 'yearly',
        'created_at': goalDate.toUtc().toIso8601String(),
      });

      _goalController.clear();
      await _loadGoals();

        // SnackBar removed for cleaner UI
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
      // SnackBar removed for cleaner UI
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

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yearly Goals',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B9080).withOpacity(0.05),
                  blurRadius: 15.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded,
                            color: AppColors.primary, size: 32.sp),
                        onPressed: () {
                          setState(() {
                            _currentYear--;
                          });
                          _loadGoals();
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            '$_currentYear',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Big picture goals',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: AppColors.primary, size: 32.sp),
                        onPressed: () {
                          setState(() {
                            _currentYear++;
                          });
                          _loadGoals();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge(
                          'Total', total.toString(), Icons.flag_rounded),
                      Container(width: 1.w, height: 40.h, color: Colors.grey[200]),
                      _buildStatBadge('Done', completed.toString(),
                          Icons.check_circle_outline_rounded),
                      Container(width: 1.w, height: 40.h, color: Colors.grey[200]),
                      _buildStatBadge('Left', (total - completed).toString(),
                          Icons.hourglass_empty_rounded),
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
                        Icon(Icons.emoji_events_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No yearly goals yet',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Set your vision for the year',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[400])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGoals,
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isCompleted = goal['is_completed'] ?? false;

                        return Dismissible(
                          key: Key(goal['id'].toString()),
                          background: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            child: Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 24.sp),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteGoal(goal['id']),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFF8F9FA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              leading: GestureDetector(
                                onTap: () =>
                                    _toggleGoal(goal['id'], isCompleted),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24.w,
                                  height: 24.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isCompleted
                                            ? AppColors.primary
                                            : Colors.grey[300]!,
                                        width: 2.w),
                                    color: isCompleted
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                  child: isCompleted
                                      ? Icon(Icons.check,
                                          size: 16.sp, color: Colors.white)
                                      : null,
                                ),
                              ),
                              title: Text(
                                goal['task_text'],
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.grey[400]
                                      : AppColors.textPrimary,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Add Yearly Goal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: TextField(
                controller: _goalController,
                decoration: InputDecoration(
                  hintText: 'Enter your goal...',
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
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                maxLines: 3,
                autofocus: true,
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: Colors.grey[600]))),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addGoal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
