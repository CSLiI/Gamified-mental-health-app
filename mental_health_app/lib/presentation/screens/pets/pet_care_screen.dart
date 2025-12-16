import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/pet_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PetCareScreen extends StatefulWidget {
  const PetCareScreen({super.key});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _bounceController;
  bool _isFeeding = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..repeat(reverse: true);
    
    // Refresh pet data and user data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PetProvider>().loadPets();
        // Refresh user data to get latest energy when screen loads
        context.read<UserProvider>().refreshUser();
      }
    });
  }
  
  @override
  void didUpdateWidget(PetCareScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh user data whenever widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().refreshUser();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh user data when app resumes
      context.read<UserProvider>().refreshUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Companion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.yellow, size: 20.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${userProvider.user?['energy'] ?? 0}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<PetProvider, UserProvider>(
        builder: (context, petProvider, userProvider, child) {
          final activePet = petProvider.activePet;
          final user = userProvider.user;
          final energy = user?['energy'] ?? 0;

          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activePet == null) {
            return _buildNoPetState(context);
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6DD5FA), // Sky blue
                  const Color(0xFF2980B9), // Deep blue
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // Pet Animation
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(width: double.infinity),
                        AnimatedBuilder(
                          animation: _bounceController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceController.value * 100),
                              child: child,
                            );
                          },
                          child: activePet['lottie_file'] != null
                              ? Transform.scale(
                                  scale: 2.2,
                                  child: Lottie.asset(
                                    activePet['lottie_file'],
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Text(
                                  activePet['emoji'] ?? '🐾',
                                  style: const TextStyle(fontSize: 200),
                                ),
                        ),
                        Positioned(
                          top: 20,
                          left: 60,
                          child: _buildSpeechBubble(_getPetMoodMessage(activePet)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pet Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activePet['name'] ?? 'Pet',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.r,
                              color: Colors.black26,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit_rounded, color: Colors.white, size: 20.sp),
                          onPressed: () => _showRenameDialog(context, activePet),
                          tooltip: 'Rename Pet',
                          constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Level ${activePet['level'] ?? 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Interaction Panel
                  Container(
                    margin: EdgeInsets.all(24.w),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatBar(
                          context,
                          'Hunger',
                          (activePet['hunger'] ?? 50) / 100,
                          Colors.orange,
                          Icons.lunch_dining,
                        ),
                        const SizedBox(height: 16),
                        _buildStatBar(
                          context,
                          'Affection',
                          (activePet['affection_level'] ?? 0) / 100,
                          Colors.pink,
                          Icons.favorite,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              context,
                              _isFeeding ? 'Feeding...' : 'Feed (10⚡)',
                              Icons.restaurant,
                              Colors.orange,
                              _isFeeding || _isPlaying ? null : () => _handleFeed(petProvider, userProvider),
                            ),
                            _buildActionButton(
                              context,
                              _isPlaying ? 'Playing...' : 'Play (10⚡)',
                              Icons.sports_baseball,
                              Colors.blue,
                              _isPlaying || _isFeeding ? null : () => _handlePlay(petProvider, userProvider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPetState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade100,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              'No Companion Selected',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Go to Rewards to adopt a pet!',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.go('/home', extra: {
                'initialIndex': 2,
                'initialTabIndex': 1, // Go to Rewards tab
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: const Text('Go to Rewards'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 14.sp,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10.h,
          ),
        ),
      ],
    );
  }

  Future<void> _handleFeed(PetProvider petProvider, UserProvider userProvider) async {
    // Get fresh energy value
    await userProvider.refreshUser();
    final currentEnergy = userProvider.user?['energy'] ?? 0;
    
    if (currentEnergy < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough energy! You have $currentEnergy⚡, need 10⚡'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() => _isFeeding = true);
    
    try {
      final result = await petProvider.feed();
      
      // Refresh to get updated energy
      await userProvider.refreshUserAfterAction();
      
        // SnackBar removed for cleaner UI
    } catch (e) {
      // Refresh on error to get correct energy value
      await userProvider.refreshUserAfterAction();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to feed pet: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFeeding = false);
      }
    }
  }
  
  Future<void> _handlePlay(PetProvider petProvider, UserProvider userProvider) async {
    // Get fresh energy value
    await userProvider.refreshUser();
    final currentEnergy = userProvider.user?['energy'] ?? 0;
    
    if (currentEnergy < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough energy! You have $currentEnergy⚡, need 10⚡'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() => _isPlaying = true);
    
    try {
      final affection = await petProvider.interact();
      
      // Refresh to get updated energy
      await userProvider.refreshUserAfterAction();
      
        // SnackBar removed for cleaner UI
    } catch (e) {
      // Refresh on error to get correct energy value
      await userProvider.refreshUserAfterAction();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play with pet: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    final isDisabled = onTap == null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: isDisabled && (label.contains('...')) 
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 24.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showRenameDialog(BuildContext context, Map<String, dynamic> pet) {
    final TextEditingController nameController = TextEditingController(text: pet['name']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Rename Pet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give your companion a special name!'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Pet Name',
                hintText: 'Enter a new name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final success = await context.read<PetProvider>().renamePet(pet['id'], newName);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed to $newName!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  String _getPetMoodMessage(Map<String, dynamic> pet) {
    final hunger = pet['hunger'] ?? 50;
    final affection = pet['affection_level'] ?? 0;
    
    if (hunger < 30) {
      return 'I\'m so hungry...';
    } else if (affection < 30) {
      return 'I\'m lonely...';
    } else if (hunger > 80 && affection > 80) {
      return 'I love you!';
    } else if (hunger > 60) {
      return 'Yum!';
    } else {
      return 'Hi there!';
    }
  }

  Widget _buildSpeechBubble(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          // Triangle for speech bubble tail
          // For simplicity, just a rounded container for now.
        ],
      ),
    );
  }
}
