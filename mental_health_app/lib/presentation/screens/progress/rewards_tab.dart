import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../widgets/level_up_dialog.dart';
import '../../widgets/reward_unlock_dialog.dart';
import '../../../core/utils/debouncer.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({super.key});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final Debouncer _actionDebouncer =
      Debouncer(duration: const Duration(milliseconds: 450));
  List<dynamic> _allRewards = [];
  Map<int, List<dynamic>> _tieredRewards = {}; // Tier -> List of rewards
  List<dynamic> _userRewards = [];
  List<dynamic> _equippedRewards = [];
  bool _isLoading = true;
  int _userXP = 0;
  int _userLevel = 1;
  bool _showTieredView = true; // Toggle between tiered and flat view

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      // Try cache first
      final cachedData = await CacheService().get<Map<String, dynamic>>(
        'rewards_data',
        maxAge: CacheService.mediumCache,
      );

      if (cachedData != null && mounted) {
        setState(() {
          _userXP = cachedData['xp'] ?? 0;
          _userLevel = cachedData['level'] ?? 1;
          _allRewards = cachedData['all'] ?? [];
          _userRewards = cachedData['user_rewards'] ?? [];
          _equippedRewards = cachedData['equipped'] ?? [];
          _tieredRewards = _groupRewardsByTier(cachedData['all'] ?? []);
          _isLoading = false;
        });
      }

      // Fetch fresh data
      final results = await Future.wait([
        _apiService.getCurrentUser(),
        _apiService.getAllRewards(),
        _apiService.getUserRewards(),
        _apiService.getEquippedRewards(),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final allRewards = results[1] as List<dynamic>;
      final userRewards = results[2] as List<dynamic>;
      final equipped = results[3] as List<dynamic>;

      // Cache fresh data
      await CacheService().set('rewards_data', {
        'xp': user['xp'] ?? 0,
        'level': user['level'] ?? 1,
        'all': allRewards,
        'user_rewards': userRewards,
        'equipped': equipped,
      });

      if (mounted) {
        setState(() {
          _userXP = user['xp'] ?? 0;
          _userLevel = user['level'] ?? 1;
          _allRewards = allRewards;
          _userRewards = userRewards;
          _equippedRewards = equipped;
          _tieredRewards = _groupRewardsByTier(allRewards);
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

  Map<int, List<dynamic>> _groupRewardsByTier(List<dynamic> rewards) {
    final Map<int, List<dynamic>> grouped = {
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
    };

    for (var reward in rewards) {
      final tier = reward['tier'] ?? 1;
      if (grouped.containsKey(tier)) {
        grouped[tier]!.add(reward);
      }
    }

    return grouped;
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
    if (!_canAfford(cost)) return;

    // Optimistic UI Update
    final previousXP = _userXP;
    final previousRewards = List<dynamic>.from(_userRewards);
    final reward = _allRewards.firstWhere((r) => r['id'] == rewardId);

    setState(() {
      _userXP -= cost;
      _userRewards.add({'reward_id': rewardId, ...reward});
    });

    try {
      final result = await _apiService.unlockReward(rewardId);

      if (result['success'] == true) {
        if (mounted) {
          // Show celebration dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RewardUnlockDialog(
              reward: reward,
              onEquip: () => _equipReward(rewardId),
            ),
          );

          // Refresh data in background to ensure consistency
          _loadRewards();

          // Check for level-up (rewards don't give XP, but user might have gained XP elsewhere)
          await _checkLevelUp();
        }
      } else {
        // Revert on failure (logic error)
        if (mounted) {
          setState(() {
            _userXP = previousXP;
            _userRewards = previousRewards;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not unlock reward.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Revert on exception
      if (mounted) {
        setState(() {
          _userXP = previousXP;
          _userRewards = previousRewards;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlock reward: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  Future<void> _equipReward(int rewardId) async {
    // Optimistic UI Update
    final previousEquipped = List<dynamic>.from(_equippedRewards);
    final reward = _allRewards.firstWhere((r) => r['id'] == rewardId);
    final category = reward['category'];

    setState(() {
      // Remove other items of same category if necessary (assuming 1 per category)
      // Note: Backend logic might differ, but for UI responsiveness we assume replacement
      _equippedRewards.removeWhere((r) {
        final rDetails = _allRewards.firstWhere(
            (all) => all['id'] == r['reward_id'],
            orElse: () => <String, dynamic>{});
        return rDetails['category'] == category;
      });
      _equippedRewards.add({'reward_id': rewardId, ...reward});
    });

    try {
      // Debounce equip to avoid rapid taps equipping multiple times
      await Future<void>.delayed(const Duration(milliseconds: 0));
      _actionDebouncer.run(() async {
        await _apiService.equipReward(rewardId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Reward equipped!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1), // Shorter duration
            ),
          );
          // Refresh to sync with server truth
          _loadRewards();
        }
      });
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _equippedRewards = previousEquipped;
        });
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SkeletonLoader.card(height: 100),
            const SizedBox(height: 24),
            SkeletonLoader.grid(
              itemCount: 6,
              crossAxisCount: 2,
              childAspectRatio: 1.1,
            ),
          ],
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

            // View toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rewards Shop',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildViewToggleButton(
                        icon: Icons.layers,
                        isSelected: _showTieredView,
                        onTap: () => setState(() => _showTieredView = true),
                      ),
                      _buildViewToggleButton(
                        icon: Icons.grid_view,
                        isSelected: !_showTieredView,
                        onTap: () => setState(() => _showTieredView = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _allRewards.isEmpty
                  ? _buildEmptyState()
                  : _showTieredView
                      ? _buildTieredView()
                      : _buildRewardsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTieredView() {
    return Column(
      children: [
        for (int tier = 1; tier <= 5; tier++)
          if (_tieredRewards[tier]?.isNotEmpty ?? false)
            _buildTierSection(tier, _tieredRewards[tier]!),
      ],
    );
  }

  Widget _buildTierSection(int tier, List<dynamic> rewards) {
    final tierLevel = _getTierUnlockLevel(tier);
    final isUnlocked = _userLevel >= tierLevel;
    final tierColor = _getTierColor(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnlocked
                  ? [tierColor, tierColor.withValues(alpha: 0.7)]
                  : [Colors.grey[400]!, Colors.grey[300]!],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTierIcon(tier),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier $tier',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isUnlocked
                          ? '${rewards.length} rewards available'
                          : 'Unlocks at Level $tierLevel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),

        // Rewards grid for this tier
        if (isUnlocked)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              final isUnlockedReward = _isUnlocked(reward['id']);
              final isEquipped = _isEquipped(reward['id']);
              final canAfford = _canAfford(reward['xp_cost']);
              return _buildRewardCard(
                  reward, isUnlockedReward, isEquipped, canAfford);
            },
          )
        else
          // Locked tier preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Blurred preview of rewards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: rewards.length > 4 ? 4 : rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final category = reward['category'] as String;
                    return Opacity(
                      opacity: 0.3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(category),
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Lock overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reach Level $tierLevel to unlock',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  int _getTierUnlockLevel(int tier) {
    switch (tier) {
      case 1:
        return 1;
      case 2:
        return 5;
      case 3:
        return 10;
      case 4:
        return 15;
      case 5:
        return 20;
      default:
        return 1;
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFCD7F32); // Bronze
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.amber; // Gold
      case 4:
        return Colors.purple; // Platinum
      case 5:
        return Colors.red; // Legendary
      default:
        return Colors.grey;
    }
  }

  IconData _getTierIcon(int tier) {
    switch (tier) {
      case 1:
        return Icons.star_border;
      case 2:
        return Icons.star_half;
      case 3:
        return Icons.star;
      case 4:
        return Icons.stars;
      case 5:
        return Icons.auto_awesome;
      default:
        return Icons.star;
    }
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
        return KeyedSubtree(
          key: ValueKey<int>(reward['id'] as int),
          child: _buildRewardCard(reward, isUnlocked, isEquipped, canAfford),
        );
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
        borderRadius: BorderRadius.circular(20),
        border: isEquipped
            ? Border.all(color: AppColors.success, width: 3)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                          color.withOpacity(0.2),
                          color.withOpacity(0.05),
                        ]
                      : [Colors.grey[200]!, Colors.grey[100]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 48,
                    color: isUnlocked ? color : Colors.grey[400],
                  ),
                  if (!isUnlocked && !canAfford)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                ],
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
                    color: isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (isEquipped)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'EQUIPPED',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isUnlocked)
                  InkWell(
                    onTap: () => _equipReward(reward['id']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'EQUIP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: canAfford
                        ? () => _unlockReward(reward['id'], reward['xp_cost'])
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: canAfford ? AppColors.warning : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canAfford
                            ? [
                                BoxShadow(
                                  color: AppColors.warning.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (canAfford)
                            const Icon(Icons.lock_open,
                                size: 12, color: Colors.white),
                          if (canAfford) const SizedBox(width: 4),
                          Text(
                            '${reward['xp_cost']} XP',
                            style: TextStyle(
                              color:
                                  canAfford ? Colors.white : Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
