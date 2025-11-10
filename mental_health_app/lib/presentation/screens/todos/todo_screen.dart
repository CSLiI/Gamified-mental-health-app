import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/services/api_service.dart';
import 'todo_list_screen.dart';
import 'weekly_goals_screen.dart';
import 'monthly_goals_screen.dart';
import 'yearly_goals_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _apiService = ApiService();
  bool _isLoadingTodos = true;
  List<dynamic> _todos = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      // Load only 'daily' period type tasks for calendar
      final todos = await _apiService.getTodos(limit: 500, periodType: 'daily');
      if (mounted) {
        setState(() {
          _todos = todos;
          _isLoadingTodos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTodos = false);
      }
    }
  }

  List<dynamic> _getTasksForDay(DateTime day) {
    return _todos.where((todo) {
      final createdAt = DateTime.parse(todo['created_at']).toLocal();
      return createdAt.year == day.year &&
          createdAt.month == day.month &&
          createdAt.day == day.day;
    }).toList();
  }

  bool _hasTasks(DateTime day) {
    return _todos.any((todo) {
      final createdAt = DateTime.parse(todo['created_at']).toLocal();
      return createdAt.year == day.year &&
          createdAt.month == day.month &&
          createdAt.day == day.day;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return 'Today';
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) return 'Tomorrow';
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) return 'Yesterday';
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

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _todos.where((t) => t['is_completed'] == true).length;
    final totalCount = _todos.length;
    final pendingCount = totalCount - completedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoadingTodos
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CACEE)))
          : RefreshIndicator(
              onRefresh: _loadTodos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF667EEA),
                            const Color(0xFF764BA2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back Button Row
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => context.go('/home'),
                                      tooltip: 'Back to Home',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.emoji_events,
                                                color: Colors.amber,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Quest Hub',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Complete quests to level up your journey',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color:
                                                Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Stats Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total',
                                      totalCount.toString(),
                                      Icons.task_alt,
                                      Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Done',
                                      completedCount.toString(),
                                      Icons.check_circle,
                                      const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Todo',
                                      pendingCount.toString(),
                                      Icons.pending_actions,
                                      const Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Calendar Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month'
                          },
                          sixWeekMonthsEnforced: true,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            // Navigate to DAILY tasks only for selected date
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TodoListScreen(selectedDate: selectedDay),
                              ),
                            ).then((_) => _loadTodos());
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF5CACEE).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(
                              color: Color(0xFF0A4B80),
                              fontWeight: FontWeight.bold,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF5CACEE),
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            weekendTextStyle: const TextStyle(
                              color: Color(0xFFEF5350),
                            ),
                            cellMargin: const EdgeInsets.all(6),
                            defaultTextStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: const TextStyle(
                              color: Color(0xFF0A4B80),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF5CACEE),
                              size: 28,
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF5CACEE),
                              size: 28,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                            ),
                            headerPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A4B80),
                            ),
                            weekendStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          eventLoader: (day) {
                            return _hasTasks(day) ? [true] : [];
                          },
                        ),
                      ),
                    ),

                    // Goals Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 12),
                            child: Text(
                              'My Goals',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A4B80),
                              ),
                            ),
                          ),
                          _buildGoalCard(
                            context,
                            'Weekly Goals',
                            'Plan your week ahead',
                            const Color(0xFF4CAF50),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WeeklyGoalsScreen(),
                              ),
                            ).then((_) => _loadTodos()),
                          ),
                          const SizedBox(height: 12),
                          _buildGoalCard(
                            context,
                            'Monthly Goals',
                            'Set monthly milestones',
                            const Color(0xFF2196F3),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MonthlyGoalsScreen(),
                              ),
                            ).then((_) => _loadTodos()),
                          ),
                          const SizedBox(height: 12),
                          _buildGoalCard(
                            context,
                            'Yearly Goals',
                            'Achieve long-term dreams',
                            const Color(0xFFFF9800),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const YearlyGoalsScreen(),
                              ),
                            ).then((_) => _loadTodos()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TodoListScreen(
                    selectedDate: _selectedDay ?? DateTime.now())),
          ).then((_) => _loadTodos());
        },
        backgroundColor: const Color(0xFF5CACEE),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Daily Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flag,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
