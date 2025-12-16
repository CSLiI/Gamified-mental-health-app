import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PetSelectionScreen extends StatefulWidget {
  const PetSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPets = [];
  List<Map<String, dynamic>> _myPets = [];
  Map<String, dynamic>? _activePet;
  int _userLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getPetCatalog(),
        _apiService.getMyPets(),
        _apiService.getFreshUserData(), // For user level
      ]);

      final allPetsResponse = results[0] as List<dynamic>;
      final myPetsResponse = results[1] as List<dynamic>;
      final userResponse = results[2] as Map<String, dynamic>;

      setState(() {
        _allPets = List<Map<String, dynamic>>.from(allPetsResponse);
        _myPets = List<Map<String, dynamic>>.from(myPetsResponse);
        _userLevel = userResponse['level'] ?? 1;

        // Find active pet from myPets
        final activePet = _myPets.firstWhere(
          (p) => p['is_active'] == true,
          orElse: () => <String, dynamic>{},
        );
        _activePet = activePet.isNotEmpty ? activePet : null;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pets: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pets: $e')),
        );
      }
    }
  }

  bool _isPetUnlocked(int petId) {
    return _myPets.any((p) => p['id'] == petId);
  }

  bool _isPetActive(int petId) {
    return _activePet != null && _activePet!['id'] == petId;
  }

  bool _canUnlock(int unlockLevel) {
    return _userLevel >= unlockLevel;
  }

  Future<void> _unlockPet(int petId, String petName) async {
    try {
      final result = await _apiService.unlockPet(petId);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Pet unlocked!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadPets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlock pet: $e')),
        );
      }
    }
  }

  Future<void> _setActivePet(int petId) async {
    try {
      final result = await _apiService.equipPet(petId);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Pet activated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadPets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate pet: $e')),
        );
      }
    }
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Collection'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Active pet display
                if (_activePet != null)
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _activePet!['emoji'],
                          style: TextStyle(fontSize: 48.sp),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Companion',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                _activePet!['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _activePet!['description'] ?? '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(Icons.favorite,
                                      color: Colors.red, size: 16.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Affection: ${_activePet!['affection_level']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
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

                // Stats
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Your Level',
                          _userLevel.toString(),
                          Icons.star,
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          'Pets Owned',
                          '${_myPets.length}/${_allPets.length}',
                          Icons.pets,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Pet grid
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(16.w),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                    ),
                    itemCount: _allPets.length,
                    itemBuilder: (context, index) {
                      final pet = _allPets[index];
                      final isUnlocked = _isPetUnlocked(pet['id']);
                      final isActive = _isPetActive(pet['id']);
                      final canUnlock = _canUnlock(pet['unlock_level']);
                      final rarityColor = _getRarityColor(pet['rarity']);

                      return GestureDetector(
                        onTap: () {
                          if (isUnlocked && !isActive) {
                            _setActivePet(pet['id']);
                          } else if (!isUnlocked && canUnlock) {
                            _showUnlockDialog(pet);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : isUnlocked
                                      ? rarityColor
                                      : Colors.grey[300]!,
                              width: isActive ? 3.w : 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Lock overlay
                              if (!isUnlocked && !canUnlock)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.lock,
                                        size: 48.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Pet emoji
                                  Text(
                                    pet['emoji'],
                                    style: TextStyle(
                                      fontSize: 64.sp,
                                      color: (!isUnlocked && !canUnlock)
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Pet name
                                  Text(
                                    pet['name'],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: (!isUnlocked && !canUnlock)
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),

                                  // Rarity badge
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rarityColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: rarityColor),
                                    ),
                                    child: Text(
                                      pet['rarity'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: rarityColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Unlock level
                                  Text(
                                    'Unlocks at Lvl ${pet['unlock_level']}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                  // Status badge
                                  if (isActive)
                                    Container(
                                      margin: EdgeInsets.only(top: 8.h),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (isUnlocked)
                                    Container(
                                      margin: EdgeInsets.only(top: 8.h),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        'TAP TO SELECT',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (canUnlock)
                                    Container(
                                      margin: EdgeInsets.only(top: 8.h),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        'TAP TO UNLOCK',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(Map<String, dynamic> pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(pet['emoji'], style: TextStyle(fontSize: 32.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(pet['name']),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pet['description'] ?? ''),
            SizedBox(height: 16.h),
            Text(
              'Unlock this pet?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
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
              _unlockPet(pet['id'], pet['name']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
