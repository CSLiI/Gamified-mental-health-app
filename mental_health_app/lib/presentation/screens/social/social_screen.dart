import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _friendRequests = [];
  List<dynamic> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final friends = await _apiService.getFriends();
      final requests = await _apiService.getReceivedFriendRequests();
      final sent = await _apiService.getSentFriendRequests();

      if (mounted) {
        setState(() {
          _friends = friends;
          _friendRequests = requests;
          _sentRequests = sent;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading social data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          '🤝 Social',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddFriendDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF667EEA)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildSentTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No friends yet',
        subtitle: 'Tap + to add friends and share your journey!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        title: 'No friend requests',
        subtitle: 'When someone sends you a request, it will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No sent requests',
        subtitle: 'Friend requests you send will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          return _buildSentRequestCard(request);
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
          Icon(icon, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
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
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF667EEA),
            child: Text(
              friend['name']?[0]?.toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4B80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${friend['level'] ?? 1}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF667EEA)),
            onPressed: () => _showFriendOptions(friend),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF667EEA),
            child: Text(
              request['name']?[0]?.toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4B80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wants to be friends',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Color(0xFF28A745)),
                onPressed: () => _acceptFriendRequest(request['id']),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Color(0xFFEF5350)),
                onPressed: () => _rejectFriendRequest(request['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF667EEA),
            child: Text(
              request['name']?[0]?.toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4B80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Request pending',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _cancelFriendRequest(request['id']),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                hintText: 'Search for friends...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendFriendRequest(searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF667EEA)),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to friend profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF667EEA)),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement messaging
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.person_remove, color: Color(0xFFEF5350)),
              title: const Text('Remove Friend'),
              onTap: () {
                Navigator.pop(context);
                _removeFriend(friend['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String query) async {
    try {
      await _apiService.sendFriendRequest(query);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error sending friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _acceptFriendRequest(int requestId) async {
    try {
      await _apiService.acceptFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _rejectFriendRequest(int requestId) async {
    try {
      await _apiService.rejectFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _cancelFriendRequest(int requestId) async {
    try {
      await _apiService.cancelFriendRequest(requestId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error cancelling friend request: $e');
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _removeFriend(int friendId) async {
    try {
      await _apiService.removeFriend(friendId);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      print('Error removing friend: $e');
      if (mounted) {
        _loadData();
      }
    }
  }
}
