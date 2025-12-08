import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/services/api_service.dart';
import 'todo_list_screen.dart';
import 'weekly_goals_screen.dart';
import 'monthly_goals_screen.dart';
import 'yearly_goals_screen.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';

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
  final Debouncer _navDebouncer =
      Debouncer(duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      // Generate daily quests for today if they don't exist
      await _apiService.generateDailyQuests();

      // Load only 'daily' period type tasks for calendar
      final todos = await _apiService.getTodos(limit: 500, periodType: 'daily');
      if (mounted) {
        setState(() {
          _todos = todos;
          _isLoadingTodos = false;
        });
      }
    } catch (e) {
      print('Error loading todos: $e');
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

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _isLoadingTodos
              ? Center(
                  child: CircularProgressIndicator(
                      color: themeProvider.primaryColor))
              : RefreshIndicator(
                  onRefresh: _loadTodos,
                  color: themeProvider.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header Section
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Back Button Row
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios_new,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        size: 20,
                                      ),
                                      onPressed: () => context.go('/home'),
                                      tooltip: 'Back to Home',
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Quest Hub',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        letterSpacing: 0.5,
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
                                        themeProvider.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Done',
                                        completedCount.toString(),
                                        Icons.check_circle_outline,
                                        AppColors.success, // Keep success green
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Pending',
                                        pendingCount.toString(),
                                        Icons.hourglass_empty,
                                        themeProvider.primaryColor.withOpacity(0.5),
                                        isPending: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Calendar Card
                        Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: themeProvider.primaryColor
                                    .withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
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
                                _navDebouncer.run(() {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TodoListScreen(
                                          selectedDate: selectedDay),
                                    ),
                                  ).then((_) => _loadTodos());
                                });
                              },
                              onPageChanged: (focusedDay) {
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: themeProvider.primaryColor
                                      .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: TextStyle(
                                  color: themeProvider.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: themeProvider.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                selectedTextStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 1,
                                weekendTextStyle: const TextStyle(
                                  color: AppColors.warning,
                                ),
                                cellMargin: const EdgeInsets.all(8),
                                defaultTextStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: themeProvider.primaryColor,
                                  size: 28,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: themeProvider.primaryColor,
                                  size: 28,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                headerPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.primaryColor,
                                  fontSize: 13,
                                ),
                                weekendStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 16),
                                child: Text(
                                  'My Goals',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              _buildGoalCard(
                                context,
                                'Weekly Goals',
                                'Plan your week ahead',
                                themeProvider.primaryColor,
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
                                AppColors.info,
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
                                AppColors.warning,
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
              _navDebouncer.run(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TodoListScreen(
                          selectedDate: _selectedDay ?? DateTime.now())),
                ).then((_) => _loadTodos());
              });
            },
            backgroundColor: themeProvider.primaryColor,
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            label: Text('Add Daily Task',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {bool isPending = false}) {
    final Color textColor = isPending ? AppColors.primaryDark : Colors.white;
    final Color bgColor = isPending ? AppColors.primaryLight : color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon,
              color:
                  isPending ? AppColors.primary : Colors.white.withOpacity(0.9),
              size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B9080).withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: color,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
