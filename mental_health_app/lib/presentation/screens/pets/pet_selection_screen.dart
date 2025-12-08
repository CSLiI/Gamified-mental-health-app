import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

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
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _activePet!['emoji'],
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Companion',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _activePet!['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _activePet!['description'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Affection: ${_activePet!['affection_level']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      const SizedBox(width: 12),
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
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : isUnlocked
                                      ? rarityColor
                                      : Colors.grey[300]!,
                              width: isActive ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
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
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.lock,
                                        size: 48,
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
                                      fontSize: 64,
                                      color: (!isUnlocked && !canUnlock)
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Pet name
                                  Text(
                                    pet['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: (!isUnlocked && !canUnlock)
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Rarity badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rarityColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: rarityColor),
                                    ),
                                    child: Text(
                                      pet['rarity'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: rarityColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Unlock level
                                  Text(
                                    'Unlocks at Lvl ${pet['unlock_level']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                  // Status badge
                                  if (isActive)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (isUnlocked)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'TAP TO SELECT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (canUnlock)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'TAP TO UNLOCK',
                                        style: TextStyle(
                                          fontSize: 10,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
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
            Text(pet['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
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
            const SizedBox(height: 16),
            Text(
              'Unlock this pet?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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
