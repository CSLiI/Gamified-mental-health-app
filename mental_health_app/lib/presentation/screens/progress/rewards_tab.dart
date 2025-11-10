import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({super.key});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allRewards = [];
  List<dynamic> _userRewards = [];
  List<dynamic> _equippedRewards = [];
  bool _isLoading = true;
  int _userXP = 0;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final user = await _apiService.getCurrentUser();
      final allRewards = await _apiService.getAllRewards();
      final userRewards = await _apiService.getUserRewards();
      final equipped = await _apiService.getEquippedRewards();

      if (mounted) {
        setState(() {
          _userXP = user['xp'] ?? 0;
          _allRewards = allRewards;
          _userRewards = userRewards;
          _equippedRewards = equipped;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading rewards: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isUnlocked(int rewardId) {
    return _userRewards.any((ur) => ur['reward_id'] == rewardId);
  }

  bool _isEquipped(int rewardId) {
    return _equippedRewards.any((er) => er['reward_id'] == rewardId);
  }

  bool _canAfford(int cost) {
    return _userXP >= cost;
  }

  Future<void> _unlockReward(int rewardId, int cost) async {
    try {
      final result = await _apiService.unlockReward(rewardId);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Reward unlocked successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadRewards();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlock reward: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _equipReward(int rewardId) async {
    try {
      await _apiService.equipReward(rewardId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Reward equipped!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadRewards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to equip reward: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    final unlockedCount = _userRewards.length;
    final totalCount = _allRewards.length;

    return RefreshIndicator(
      onRefresh: _loadRewards,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildXPCard(unlockedCount, totalCount),
            const SizedBox(height: 24),
            const Text(
              'Rewards Shop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4B80),
              ),
            ),
            const SizedBox(height: 16),
            if (_allRewards.isEmpty)
              _buildEmptyState()
            else
              _buildRewardsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildXPCard(int unlocked, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_userXP XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Unlocked', '$unlocked/$total'),
              _buildStat('Equipped', '${_equippedRewards.length}'),
              _buildStat('Available', '${total - unlocked}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _allRewards.length,
      itemBuilder: (context, index) {
        final reward = _allRewards[index];
        final isUnlocked = _isUnlocked(reward['id']);
        final isEquipped = _isEquipped(reward['id']);
        final canAfford = _canAfford(reward['xp_cost']);
        return _buildRewardCard(reward, isUnlocked, isEquipped, canAfford);
      },
    );
  }

  Widget _buildRewardCard(
    Map<String, dynamic> reward,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
  ) {
    final category = reward['category'] as String;
    final color = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isEquipped ? Border.all(color: AppColors.success, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1)
                        ]
                      : [Colors.grey[200]!, Colors.grey[100]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 50,
                      color: isUnlocked ? color : Colors.grey[400],
                    ),
                    if (!isUnlocked && !canAfford) const SizedBox(height: 8),
                    if (!isUnlocked && !canAfford)
                      const Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  reward['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isUnlocked ? const Color(0xFF0A4B80) : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (isEquipped)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'EQUIPPED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  InkWell(
                    onTap: () => _equipReward(reward['id']),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EQUIP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: canAfford
                        ? () => _unlockReward(reward['id'], reward['xp_cost'])
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: canAfford ? AppColors.warning : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${reward['xp_cost']} XP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Rewards Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Earn XP to unlock amazing rewards!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cosmetic':
        return const Color(0xFF9C27B0);
      case 'pet':
        return const Color(0xFFFF9800);
      case 'environment':
        return const Color(0xFF4CAF50);
      case 'accessory':
        return const Color(0xFF2196F3);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cosmetic':
        return Icons.auto_awesome;
      case 'pet':
        return Icons.pets;
      case 'environment':
        return Icons.landscape;
      case 'accessory':
        return Icons.diamond;
      default:
        return Icons.card_giftcard;
    }
  }
}
