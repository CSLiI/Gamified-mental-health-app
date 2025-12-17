import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/services/cache_service.dart';
import '../../widgets/level_up_dialog.dart';
import '../../widgets/reward_unlock_dialog.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/pet_provider.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/reward_catalog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({super.key});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final Debouncer _actionDebouncer =
      Debouncer(duration: const Duration(milliseconds: 450));
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> _allRewards = [];
  Map<int, List<dynamic>> _tieredRewards = {}; // Tier -> List of rewards
  List<dynamic> _userRewards = [];
  List<dynamic> _equippedRewards = [];
  bool _isLoading = true;
  int _userXP = 0;
  int _totalXP = 0; // Total XP earned (lifetime)
  int _spentXP = 0; // XP spent on rewards
  int _userLevel = 1;
  bool _showTieredView = true; // Toggle between tiered and flat view
  String _activeCategory = 'themes';
  String _searchQuery = '';
  late AnimationController _carouselController;

  // Built-in shop catalog (no external assets - MUST match ThemeProvider IDs)
  late final List<Map<String, dynamic>> _builtinCatalog = RewardCatalog.rewards;

  @override
  void initState() {
    super.initState();
    _carouselController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _loadRewards(forceRefresh: true); // Always force refresh on init
    
    // Load pets once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().loadPets();
    });
  }

  Widget _buildXPCard(int unlocked, int total) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary, // Solid color
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available XP',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.onTertiary, size: 24.sp),
                        SizedBox(width: 8.w),
                        Text(
                          '$_userXP',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'XP',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color:
                                          Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                                      size: 16.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Total Earned',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$_totalXP XP',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onTertiary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_bag,
                                      color:
                                          Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                                      size: 16.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Spent on Rewards',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '-$_spentXP XP',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onTertiary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Divider(
                              color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.1),
                              height: 1.h),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.6), size: 16.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$_userXP XP',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onTertiary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Unlocked', '$unlocked/$total'),
              _buildStat('Equipped', '${_equippedRewards.length}'),
              _buildStat('Level', '$_userLevel'),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onTertiary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards({bool forceRefresh = false}) async {
    try {
      // Get user ID for user-specific storage
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.userId;

      if (userId == null) {
        // print('⚠️ Rewards: No user ID available, skipping storage load');
        return;
      }

      // Fetch fresh user data for XP and level (force rebuild)
      final userData = await _apiService.getFreshUserData();
      final totalXp = userData['xp'] as int? ?? 0;
      final correctLevel = userData['level'] as int? ?? 1;

      // Fetch rewards data from backend
      final backendRewards = await _apiService.getAllRewards();
      var userRewardsRaw = await _apiService.getUserRewards();
      var equippedRaw = await _apiService.getEquippedRewards();
      
      // DEBUG: Print first item to see structure
      if (userRewardsRaw is List && userRewardsRaw.isNotEmpty) {
        print('🔍 DEBUG: First userReward = ${userRewardsRaw.first}');
      } else {
        print('🔍 DEBUG: userRewardsRaw is empty - checking local storage for sync');
      }
      
      // DEBUG: Check ALL keys to find where data is hiding
      final allKeys = await _secureStorage.readAll();
      print('🔍 DEBUG STORAGE: Found ${allKeys.length} keys: ${allKeys.keys.toList()}');

      // Load local storage data
      var builtinUserRewardsJson = await _secureStorage.read(
        key: StorageKeys.builtinUserRewards(userId),
      );
      var builtinEquippedJson = await _secureStorage.read(
        key: StorageKeys.builtinEquippedRewards(userId),
      );
      var spentXpJson = await _secureStorage.read(
        key: StorageKeys.builtinXpSpent(userId),
      );

      final builtinUserRewards = builtinUserRewardsJson != null
          ? (jsonDecode(builtinUserRewardsJson) as List)
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final builtinEquipped = builtinEquippedJson != null
          ? (jsonDecode(builtinEquippedJson) as List)
              .cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final spentXp = spentXpJson != null ? int.parse(spentXpJson) : 0;

      // Normalize backend response: ensure 'reward_id' field exists
      final userRewards = (userRewardsRaw as List).map((ur) {
        if (ur is Map<String, dynamic>) {
          // If it has 'id' but not 'reward_id', copy id to reward_id
          if (ur.containsKey('id') && !ur.containsKey('reward_id')) {
            return {...ur, 'reward_id': ur['id']};
          }
        }
        return ur;
      }).toList();
      
      final equipped = (equippedRaw as List).map((er) {
        if (er is Map<String, dynamic>) {
          if (er.containsKey('id') && !er.containsKey('reward_id')) {
            return {...er, 'reward_id': er['id']};
          }
        }
        return er;
      }).toList();
      
      // Normalize local data too
      final normalizedLocal = builtinUserRewards.map((ur) {
             if (ur.containsKey('id') && !ur.containsKey('reward_id')) {
               return {...ur, 'reward_id': ur['id']};
             }
             return ur;
      }).toList();
      
      // FETCH BACKEND BUILTIN DATA
      List<Map<String, dynamic>> backendBuiltinPurchased = [];
      List<Map<String, dynamic>> backendBuiltinEquipped = [];
      int backendBuiltinXcSpent = 0;
      
      try {
        final builtinData = await _apiService.getBuiltinRewardsData();
        if (builtinData['purchased'] is List) {
          backendBuiltinPurchased = (builtinData['purchased'] as List).cast<Map<String, dynamic>>();
        }
        if (builtinData['equipped'] is List) {
          backendBuiltinEquipped = (builtinData['equipped'] as List).cast<Map<String, dynamic>>();
        }
        if (builtinData['xp_spent'] is int) {
          backendBuiltinXcSpent = builtinData['xp_spent'];
        }
        print('✅ Loaded ${backendBuiltinPurchased.length} builtin rewards from Backend');
      } catch (e) {
        print('⚠️ Failed to load backend builtin data: $e');
      }

      // Normalize backend builtin response
      final normalizedBackendBuiltin = backendBuiltinPurchased.map((ur) {
         if (ur.containsKey('id') && !ur.containsKey('reward_id')) {
           return {...ur, 'reward_id': ur['id']};
         }
         return ur;
      }).toList();

      // DEDUPLICATE AND MERGE (Backend + Local)
      // Use a Map to ensure unique reward_ids. Backend takes precedence.
      final Map<int, Map<String, dynamic>> combinedRewardsMap = {};
      
      for (var r in normalizedBackendBuiltin) {
        if (r['reward_id'] != null) combinedRewardsMap[r['reward_id']] = r;
      }
      for (var r in normalizedLocal) {
        if (r['reward_id'] != null) {
          // Only add local if not already present (Backend is truth)
          combinedRewardsMap.putIfAbsent(r['reward_id'], () => r);
        }
      }
      final uniqueBuiltinRewards = combinedRewardsMap.values.toList();
      
      // SAVE TO LOCAL STORAGE (Cache for ThemeProvider)
      await _secureStorage.write(
        key: StorageKeys.builtinUserRewards(userId),
        value: jsonEncode(uniqueBuiltinRewards),
      );
      // Also cache XP logic if we want consistency? 
      // ThemeProvider doesn't check XP.

      
      // ONE-TIME SYNC: Only if we have local data to sync
      // (This logic is less relevant now that we merge/overwrite, but kept for legacy sync attempts)
      if (userRewardsRaw is List && userRewardsRaw.isEmpty && normalizedLocal.isNotEmpty) {
           // ... (Sync logic remains, though likely unused if backend has data)
      }

        // Correct Logic:
        final finalSpentXp = (spentXp > backendBuiltinXcSpent) ? spentXp : backendBuiltinXcSpent;
        
        setState(() {
          // FIXED: user.xp from backend is TOTAL lifetime XP, not available
          // Available XP = Total XP - Spent XP
          _totalXP = totalXp;                    // Total lifetime XP earned
          _spentXP = finalSpentXp;               // XP spent on rewards
          _userXP = _totalXP - _spentXP;         // Available XP to spend
          
          _userLevel = correctLevel;
          // Merge backend rewards with builtin catalog
          _allRewards = [
            ...backendRewards,
            ..._builtinCatalog,
          ];
          // Merge backend user rewards with built-in rewards
          _userRewards = [
            ...userRewards, // Generic
            ...uniqueBuiltinRewards, // Unified List
          ];
          // Merge backend equipped with built-in equipped
          _equippedRewards = [
             ...equipped,
             ...backendBuiltinEquipped, // Backend Equipped state
             ...builtinEquipped // Local Equipped state (Deduplication needed here too?)
          ];
          // Basic dedupe for equipped to prevent UI glitch
          // (Last one wins usually in UI rendering, but let's be clean?)
           // Ideally we de-dupe equipped too, but list length is small.

          _tieredRewards = _groupRewardsByTier(_allRewards);
          _isLoading = false;
        });
    } catch (e) {
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

    // Check if this is a built-in catalog item (frontend-only)
    final isBuiltinReward = rewardId >= 10000;

    setState(() {
      _userXP -= cost;
      _userRewards.add({'reward_id': rewardId, ...reward});
    });

    try {
      if (isBuiltinReward) {
        // Handle built-in rewards via Backend API + Local Storage
        // Get user ID for user-specific storage
        final userId = context.read<UserProvider>().userId;
        if (userId == null) {
          throw Exception('No user ID available');
        }

        // Call Backend API
        await _apiService.purchaseBuiltinReward(
            rewardId, reward['category'], cost);

        // Update Secure Storage (to keep ThemeProvider in sync)
        final builtinUserRewardsJson = await _secureStorage.read(
            key: StorageKeys.builtinUserRewards(userId));
        final builtinUserRewards = builtinUserRewardsJson != null
            ? (jsonDecode(builtinUserRewardsJson) as List)
                .cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        
        // Only store reward_id and category
        builtinUserRewards.add({
          'reward_id': rewardId,
          'category': reward['category'],
        });
        await _secureStorage.write(
          key: StorageKeys.builtinUserRewards(userId),
          value: jsonEncode(builtinUserRewards),
        );

        // Save XP spent
        final spentXpJson =
            await _secureStorage.read(key: StorageKeys.builtinXpSpent(userId));
        final spentXp = spentXpJson != null ? int.parse(spentXpJson) : 0;
        await _secureStorage.write(
          key: StorageKeys.builtinXpSpent(userId),
          value: (spentXp + cost).toString(),
        );

        if (mounted) {
          // Clear cache to force refresh with new XP
          await CacheService().remove('rewards_data');
          await CacheService().remove('profile_data');

          // Show celebration dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RewardUnlockDialog(
              reward: reward,
              onEquip: () => _equipReward(rewardId),
            ),
          );
        }
      } else {
        // Backend rewards - make API call
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
      // Level up check failed silently
    }
  }

  Future<void> _unequipReward(int rewardId) async {
    // Optimistic UI Update
    final previousEquipped = List<dynamic>.from(_equippedRewards);
    final reward = _allRewards.firstWhere((r) => r['id'] == rewardId);
    final category = reward['category'];

    // Check if this is a built-in catalog item (frontend-only)
    final isBuiltinReward = rewardId >= 10000;

    setState(() {
      _equippedRewards.removeWhere((r) => r['reward_id'] == rewardId);
    });

    try {
      if (isBuiltinReward) {
        // Handle built-in rewards via Backend API + Local Storage
        final userId = context.read<UserProvider>().userId;
        if (userId == null) {
          throw Exception('No user ID available');
        }

        // Call Backend API
        await _apiService.unequipBuiltinReward(rewardId);

        // Update Secure Storage
        final builtinEquippedJson = await _secureStorage.read(
            key: StorageKeys.builtinEquippedRewards(userId));
        final builtinEquipped = builtinEquippedJson != null
            ? (jsonDecode(builtinEquippedJson) as List)
                .cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        // Remove this specific item
        builtinEquipped.removeWhere((r) => r['reward_id'] == rewardId);

        await _secureStorage.write(
          key: StorageKeys.builtinEquippedRewards(userId),
          value: jsonEncode(builtinEquipped),
        );

        // Clear profile cache to force refresh
        await CacheService().remove('profile_data');

        // Notify ThemeProvider to refresh if theme, banner, or font was unequipped
        if (mounted &&
            (category == 'themes' ||
                category == 'banners' ||
                category == 'fonts')) {
          print(
              '🔄 Unequipping ${category}: Refreshing ThemeProvider with userId=$userId');
          await context.read<ThemeProvider>().refreshTheme(userId);
          // print('✅ ThemeProvider refresh complete');
        }

        if (mounted) {
          // SnackBar removed for cleaner UI
          _loadRewards();
        }
      } else {
        // Backend rewards - make API call to unequip
        await _apiService.unequipReward(rewardId);

        if (mounted) {
          // SnackBar removed for cleaner UI
          _loadRewards();
        }
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _equippedRewards = previousEquipped;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unequip: \$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _equipReward(int rewardId) async {
    // Optimistic UI Update
    final previousEquipped = List<dynamic>.from(_equippedRewards);
    final reward = _allRewards.firstWhere((r) => r['id'] == rewardId);
    final category = reward['category'];

    // Check if this is a built-in catalog item (frontend-only)
    final isBuiltinReward = rewardId >= 10000;

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
      if (isBuiltinReward) {
        // Handle built-in rewards via Backend API + Local Storage
        // Get user ID for user-specific storage
        final userId = context.read<UserProvider>().userId;
        if (userId == null) {
          throw Exception('No user ID available');
        }

        // Call Backend API
        await _apiService.equipBuiltinReward(rewardId, category);

        // Update Secure Storage
        final builtinEquippedJson = await _secureStorage.read(
            key: StorageKeys.builtinEquippedRewards(userId));
        final builtinEquipped = builtinEquippedJson != null
            ? (jsonDecode(builtinEquippedJson) as List)
                .cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        // Remove other items of same category
        builtinEquipped.removeWhere((r) => r['category'] == category);
        // Only store reward_id and category
        builtinEquipped.add({
          'reward_id': rewardId,
          'category': category,
        });

        await _secureStorage.write(
          key: StorageKeys.builtinEquippedRewards(userId),
          value: jsonEncode(builtinEquipped),
        );

        // Clear profile cache to force refresh of equipped items
        await CacheService().remove('profile_data');

        // Notify ThemeProvider to refresh if theme, banner, or font was equipped
        if (mounted &&
            (category == 'themes' ||
                category == 'banners' ||
                category == 'fonts')) {
          print(
              '🔄 Equipping ${category}: Refreshing ThemeProvider with userId=$userId');
          await context.read<ThemeProvider>().refreshTheme(userId);
        }

        if (mounted) {
          // SnackBar removed for cleaner UI
          // Reload to refresh UI
          _loadRewards();
        }
      } else {
        // Backend rewards - make API call
        await Future<void>.delayed(const Duration(milliseconds: 0));
        _actionDebouncer.run(() async {
          await _apiService.equipReward(rewardId);

          if (mounted) {
            // SnackBar removed for cleaner UI
            // Refresh to sync with server truth
            _loadRewards();
          }
        });
      }
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
    // super.build(context); // Removed AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            SkeletonLoader.card(height: 100.h),
            SizedBox(height: 24.h),
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
      onRefresh: () => _loadRewards(forceRefresh: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildXPCard(unlockedCount, totalCount),
            SizedBox(height: 16.h),
            _buildShopControls(),
            SizedBox(height: 12.h),
            _buildShopGrid(),
          ],
        ),
      ),
    );
  }



  Widget _buildShopControls() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('themes', Icons.gradient, 'Themes'),
          SizedBox(width: 8.w),
          _buildCategoryChip('fonts', Icons.text_fields_rounded, 'Fonts'),
          SizedBox(width: 8.w),
          _buildCategoryChip('banners', Icons.flag_rounded, 'Banners'),
          SizedBox(width: 8.w),
          _buildCategoryChip('companions', Icons.pets_rounded, 'Companions'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, IconData icon, String label) {
    final selected = _activeCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16.sp,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopGrid() {
    if (_activeCategory == 'companions') {
      return _buildPetGrid();
    }

    final items = _allRewards.where((r) {
      final cat = (r['category'] as String).toLowerCase();
      final name = (r['name'] as String).toLowerCase();
      final catMatch = cat == _activeCategory;
      final searchMatch = _searchQuery.isEmpty || name.contains(_searchQuery);
      return catMatch && searchMatch;
    }).toList();

    if (items.isEmpty) return _buildEmptyState(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final reward = items[index];
        final isUnlocked = _isUnlocked(reward['id']);
        final isEquipped = _isEquipped(reward['id']);
        final canAfford = _canAfford(reward['xp_cost']);
        return _buildShopCard(reward, isUnlocked, isEquipped, canAfford, context);
      },
    );
  }

  Widget _buildShopCard(
    Map<String, dynamic> reward,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isEquipped ? Theme.of(context).colorScheme.secondary : Theme.of(context).dividerColor,
            width: 2.w),
        boxShadow: [
          if (isEquipped)
            BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: 1.r),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.r,
              offset: Offset(0, 4.h)),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: _buildPreviewFor(reward)),
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
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildEquipOrUnlock(reward, isUnlocked, isEquipped, canAfford, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipOrUnlock(
    Map<String, dynamic> reward,
    bool isUnlocked,
    bool isEquipped,
    bool canAfford,
    BuildContext context,
  ) {
    if (isEquipped) {
      return InkWell(
        onTap: () => _unequipReward(reward['id']),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Theme.of(context).colorScheme.secondary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 14.sp, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 4.w),
              Text('EQUIPPED',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (isUnlocked) {
      return InkWell(
        onTap: () => _equipReward(reward['id']),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h)),
            ],
          ),
          child: Text('EQUIP',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }

    return InkWell(
      onTap: canAfford
          ? () => _unlockReward(reward['id'], reward['xp_cost'])
          : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: canAfford ? Theme.of(context).colorScheme.tertiary : Theme.of(context).disabledColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h))
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canAfford)
              Icon(Icons.lock_open, size: 12.sp, color: Colors.white),
            if (canAfford) SizedBox(width: 4.w),
            Text(
              '${reward['xp_cost']} XP',
              style: TextStyle(
                  color: canAfford ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }



  // Preview builders without external assets
  Widget _buildPreviewFor(Map<String, dynamic> reward) {
    final category = reward['category'] as String;
    switch (category) {
      case 'themes':
        return _ThemePreview(
            color1: reward['color1'], color2: reward['color2']);
      case 'fonts':
        return _FontPreview(
            fontFamily: reward['preview'].toString().replaceAll('font_', '').capitalize());
      case 'banners':
        return _BannerPreview(
            color1: reward['color1'], color2: reward['color2']);

      default:
        return const SizedBox();
    }
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
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isUnlocked ? tierColor : Theme.of(context).disabledColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: tierColor.withOpacity(0.3),
                      blurRadius: 10.r,
                      offset: Offset(0, 5.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getTierIcon(tier),
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier $tier',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isUnlocked
                          ? '${rewards.length} rewards available'
                          : 'Unlocks at Level $tierLevel',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 24.sp,
                ),
            ],
          ),
        ),

        // Rewards grid for this tier
        if (isUnlocked)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              final isUnlockedReward = _isUnlocked(reward['id']);
              final isEquipped = _isEquipped(reward['id']);
              final canAfford = _canAfford(reward['xp_cost']);
              return _buildShopCard(
                  reward, isUnlockedReward, isEquipped, canAfford, context);
            },
          )
        else
          // Locked tier preview
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Stack(
              children: [
                // Blurred preview of rewards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                  ),
                  itemCount: rewards.length > 4 ? 4 : rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final category = reward['category'] as String;
                    return Opacity(
                      opacity: 0.3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(category),
                            size: 40.sp,
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
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 48.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Reach Level $tierLevel to unlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
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

        SizedBox(height: 32.h),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 80.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Rewards Available',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Earn XP to unlock amazing rewards!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category.toLowerCase()) {
      case 'themes':
        return const Color(0xFF4FC3F7);
      case 'fonts':
        return const Color(0xFF5C6BC0);
      case 'banners':
        return const Color(0xFFFF8A65);
      case 'frames':
        return const Color(0xFF9C27B0);
      case 'profile':
        return const Color(0xFF66BB6A);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'themes':
        return Icons.gradient;
      case 'fonts':
        return Icons.text_fields_rounded;
      case 'banners':
        return Icons.flag_rounded;
      case 'frames':
        return Icons.crop_square_rounded;
      case 'profile':
        return Icons.badge_rounded;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildPetGrid() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        if (petProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (petProvider.catalog.isEmpty) {
          if (petProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load pets',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  TextButton(
                    onPressed: () => petProvider.loadPets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 48, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No companions available yet',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: petProvider.catalog.length,
          itemBuilder: (context, index) {
            final pet = petProvider.catalog[index];
            final userPet = petProvider.myPets.firstWhere(
              (p) => p['id'] == pet['id'],
              orElse: () => <String, dynamic>{},
            );
            final isUnlocked = userPet.isNotEmpty;
            final isActive = userPet['is_active'] == true;
            final canAfford = _canAfford(0); // Pets might cost XP later

            return _buildPetCard(pet, isUnlocked, isActive, canAfford, petProvider, context);
          },
        );
      },
    );
  }

  Widget _buildPetCard(
    Map<String, dynamic> pet,
    bool isUnlocked,
    bool isActive,
    bool canAfford,
    PetProvider provider,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isActive ? Theme.of(context).colorScheme.secondary : Theme.of(context).dividerColor,
            width: isActive ? 2.w : 1.w),
        boxShadow: [
          if (isActive)
            BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: 1.r),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.r,
              offset: Offset(0, 4.h)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero, // No padding for maximum size
              child: pet['lottie_file'] != null
                  ? Transform.scale(
                      scale: 1.5, // Significant zoom to fill card
                      child: Lottie.asset(
                        pet['lottie_file'],
                        fit: BoxFit.contain,
                      ),
                    )
                  : Center(
                      child: Text(
                        pet['emoji'] ?? '🐾',
                        style: TextStyle(fontSize: 100.sp), // Massive emoji size
                      ),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                Text(
                  pet['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                if (isActive)
                  InkWell(
                    onTap: null, // Already active
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Theme.of(context).colorScheme.secondary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 14.sp, color: Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 4.w),
                          Text('COMPANION',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else if (isUnlocked)
                  InkWell(
                    onTap: () => provider.equipPet(pet['id']),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h)),
                        ],
                      ),
                      child: Text('EQUIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => provider.unlockPet(pet['id']),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open,
                              size: 12.sp,
                              color: Theme.of(context).colorScheme.onTertiary),
                          SizedBox(width: 4.w),
                          Text(
                            'Unlock', // Add cost later
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold),
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
}

// ==== Preview widgets (no assets) ====
class _ThemePreview extends StatelessWidget {
  final Color color1;
  final Color color2;
  const _ThemePreview({required this.color1, required this.color2});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
      ),
      child: Stack(
        children: const [
          Positioned(
              top: 12,
              left: 12,
              child: Icon(Icons.wb_sunny_rounded, color: Colors.white70)),
          Positioned(
              bottom: 12,
              right: 12,
              child: Icon(Icons.cloud_rounded, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _BannerPreview extends StatelessWidget {
  final Color color1;
  final Color color2;
  const _BannerPreview({required this.color1, required this.color2});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
      ),
      child: Center(
        child: Container(
          width: double.infinity,
          height: 32.h,
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Banner Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontPreview extends StatelessWidget {
  final String fontFamily;
  const _FontPreview({required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    // Map preview string to actual Google Font name
    String googleFontName = 'Nunito';
    if (fontFamily.toLowerCase().contains('outfit')) googleFontName = 'Outfit';
    if (fontFamily.toLowerCase().contains('inter')) googleFontName = 'Inter';
    if (fontFamily.toLowerCase().contains('quicksand')) googleFontName = 'Quicksand';
    if (fontFamily.toLowerCase().contains('playfair')) googleFontName = 'Playfair Display';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: GoogleFonts.getFont(
                googleFontName,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'The quick brown fox',
              style: GoogleFonts.getFont(
                googleFontName,
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
