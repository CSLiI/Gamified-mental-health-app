import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
//   List<dynamic> _encouragements = [];
//   List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<NotificationProvider>(context, listen: false).loadnotifications();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              Color(0xFFF8F9FE),
              Color(0xFFE8EAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => context.go('/home'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B8BA8),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, size: 16),
                          const SizedBox(width: 6),
                          const Flexible(
                              child: Text('Encourage',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events, size: 16),
                          const SizedBox(width: 6),
                          const Flexible(
                              child: Text('Challenges',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEncouragementTab(),
                          _buildChallengesTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEncouragementTab() {
    final provider = Provider.of<NotificationProvider>(context);
    final encouragements = provider.allEncouragements;
    
    if (encouragements.isEmpty) {
      if (provider.isLoading) {
         return Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'No encouragements yet',
        subtitle: 'When friends send you encouragement, it will appear here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: encouragements.length,
        itemBuilder: (context, index) {
          final encouragement = encouragements[index];
          return _buildEncouragementCard(encouragement);
        },
      ),
    );
  }

  Widget _buildChallengesTab() {
    final provider = Provider.of<NotificationProvider>(context);
    final messages = provider.allChallenges;

    if (messages.isEmpty) {
      if (provider.isLoading) {
        return Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No challenges or alerts',
        subtitle: 'When friends challenge you or system alerts arrive, they will appear here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildChallengeCard(message);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRedirect(String? route, Map<String, dynamic> data) {
    if (route == '/profile') {
      context.go('/home', extra: {'initialIndex': 4});
      return;
    }
    
    if (route == '/mood') {
      context.go('/home', extra: {'initialIndex': 3});
      return;
    }

    if (route != null && route.isNotEmpty) {
      context.push(route);
      return;
    }

    // Fallback: Smart navigation based on data
    if (data['sender_id'] != null && data['is_system'] != true) {
      // Navigate to friend profile
      final senderId = data['sender_id'];
      final senderName = '${data['sender_first_name']} ${data['sender_last_name']}'.trim();
      context.push('/friend/$senderId?name=$senderName');
      return;
    }
    
    // If it's a mood-related system message without a route
    if (data['is_system'] == true && (data['message']?.toString().toLowerCase().contains('mood') ?? false)) {
       context.go('/home', extra: {'initialIndex': 3});
       return;
    }
  }

  Widget _buildEncouragementCard(Map<String, dynamic> encouragement) {
    final isSystem = encouragement['is_system'] == true;
    final senderName =
        '${encouragement['sender_first_name'] ?? ''} ${encouragement['sender_last_name'] ?? ''}'
            .trim();
    final message = encouragement['message'] ?? '';
    final isRead = encouragement['is_read'] ?? false;
    final createdAt = DateTime.parse(encouragement['created_at']).toLocal();
    final timeAgo = _getTimeAgo(createdAt);
    final redirectRoute = encouragement['redirect_route'];

    return GestureDetector(
      onTap: () => _handleRedirect(redirectRoute, encouragement),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isRead ? Colors.white : AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? Colors.grey[200]!
                : AppColors.success.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.7)
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName.isEmpty ? 'Unknown' : senderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isRead) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    if (isSystem) {
                      context.read<NotificationProvider>().markSystemRead(encouragement['id']);
                      return;
                    }
                    
                    try {
                      await _apiService
                          .markEncouragementRead(encouragement['id']);
                      _loadData();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark as read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> message) {
    final isSystem = message['is_system'] == true;
    final senderName =
        '${message['sender_first_name'] ?? ''} ${message['sender_last_name'] ?? ''}'
            .trim();
    final content = message['message'] ?? '';
    final isRead = message['is_read'] ?? false;
    final createdAt = DateTime.parse(message['created_at']).toLocal();
    final timeAgo = _getTimeAgo(createdAt);
    final redirectRoute = message['redirect_route'];

    return GestureDetector(
      onTap: () => _handleRedirect(redirectRoute, message),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isRead ? Colors.white : AppColors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? Colors.grey[200]!
                : AppColors.warning.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning,
                        AppColors.warning.withValues(alpha: 0.7)
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName.isEmpty ? 'Unknown' : senderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            
            // Mark Read Button for System Alerts (Challenges might not be markable?)
             if (!isRead && isSystem) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    context.read<NotificationProvider>().markSystemRead(message['id']);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark as read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
