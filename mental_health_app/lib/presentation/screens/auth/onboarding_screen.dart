import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  const OnboardingScreen({super.key, this.registrationData});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _apiService = ApiService();
  final _pageController = PageController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  int _currentPage = 0;

  // Registration data
  String? _email;
  String? _password;

  // User profile variables
  DateTime? _selectedDate;

  // Character selection variables
  List<Map<String, dynamic>> _characterOptions = [];
  int? _selectedCharacterId;
  bool _isLoading = false;

  // Interest selection variables
  List<Map<String, dynamic>> _allInterests = [];
  Set<int> _selectedInterestIds = {};
  bool _loadingInterests = false;

  @override
  void initState() {
    super.initState();
    _email = widget.registrationData?['email'];
    _password = widget.registrationData?['password'];
    _setupCharacterOptions();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() => _loadingInterests = true);
    try {
      final interests = await _apiService.getAllInterests();
      setState(() {
        _allInterests = List<Map<String, dynamic>>.from(interests);
        _loadingInterests = false;
      });
    } catch (e) {
      setState(() => _loadingInterests = false);
      print('Error loading interests: $e');
    }
  }

  void _setupCharacterOptions() {
    // Define character options (ID, gender, number, name, description)
    _characterOptions = [
      {
        'id': 1,
        'gender': 'Boy',
        'number': 1,
        'name': 'Calm Boy 1',
        'description': 'A focused and mindful companion for your journey',
        'color': const Color(0xFF5CACEE), // Blue
        'gifPath': 'assets/images/Boy_Gif_33FPS/CalmBoy1.gif',
      },
      {
        'id': 2,
        'gender': 'Boy',
        'number': 2,
        'name': 'Calm Boy 2',
        'description': 'A reliable friend who helps you stay grounded',
        'color': const Color(0xFF66BB6A), // Green
        'gifPath': 'assets/images/Boy_Gif_33FPS/CalmBoy2.gif',
      },
      {
        'id': 3,
        'gender': 'Girl',
        'number': 1,
        'name': 'Calm Girl 1',
        'description': 'A supportive guide for your wellness journey',
        'color': const Color(0xFFFF8EC4), // Pink
        'gifPath': 'assets/images/Girl_Gif_33FPS/CalmGirl1.gif',
      },
      {
        'id': 4,
        'gender': 'Girl',
        'number': 2,
        'name': 'Calm Girl 2',
        'description': 'An encouraging partner for your daily goals',
        'color': const Color(0xFFFFD54F), // Yellow
        'gifPath': 'assets/images/Girl_Gif_33FPS/CalmGirl2.gif',
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 13)), // 13+ years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    // Validate profile data
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your first name'),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your birthday'),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedCharacterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a character'),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isGoogleUser = _password == 'google_oauth';
      
      if (!isGoogleUser) {
        // Regular user - create account with complete data
        await _apiService.register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _email!,
          password: _password!,
          dateOfBirth: _selectedDate!.toIso8601String().split('T')[0],
          gender: 'other', // Can be updated later in profile
        );

        // Auto-login after successful registration
        await _apiService.login(
          email: _email!,
          password: _password!,
        );
      } else {
        // Google user - already logged in, just update profile
        await _apiService.updateProfile({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'date_of_birth': _selectedDate!.toIso8601String().split('T')[0],
          'gender': 'other',
        });
      }

      // Find the selected character option
      final selectedCharacter = _characterOptions.firstWhere(
        (char) => char['id'] == _selectedCharacterId,
        orElse: () => _characterOptions[0],
      );

      // Choose character
      await _apiService.chooseCharacter(_selectedCharacterId!);

      // Save selected interests
      if (_selectedInterestIds.isNotEmpty) {
        try {
          await _apiService.updateUserInterests(_selectedInterestIds.toList());
        } catch (e) {
          print('Error saving interests: $e');
          // Don't block onboarding if interests fail to save
        }
      }

      // Cache to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_character_id', selectedCharacter['id']);
      await prefs.setString(
          'selected_character_gender', selectedCharacter['gender']);
      await prefs.setInt(
          'selected_character_number', selectedCharacter['number']);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FE),
              Color(0xFFE8EAFC),
              Color(0xFFD6D9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    FocusScope.of(context)
                        .unfocus(); // Dismiss keyboard on swipe
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildUsernamePage(),
                    _buildBirthdayPage(),
                    _buildFeaturesPage(),
                    _buildCharacterSelectionPage(),
                    _buildInterestsPage(), // New interests selection page
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Color(0xFF6C5CE7)
                                : Color(0xFF6C5CE7).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C5CE7).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentPage == 4 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 100.w,
                height: 100.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6C5CE7).withOpacity(0.15),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Text(
              'Welcome to Echo',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3)),
            ),
            child: Text(
              'Track mood, journal thoughts,\nand grow with your character companion',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUsernamePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.0.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  Container(
                    width: 100.w,
                    height: 100.w,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C5CE7).withOpacity(0.3),
                          blurRadius: 15.r,
                          spreadRadius: 3.r,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C5CE7).withOpacity(0.1),
                          blurRadius: 15.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: Text(
                      'What should we call you?',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This helps personalize your experience',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF6B8BA8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6C5CE7).withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _firstNameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C5CE7),
                          ),
                          decoration: InputDecoration(
                            hintText: 'First Name',
                            hintStyle: TextStyle(
                              color: const Color(0xFF6C5CE7).withOpacity(0.4),
                              fontSize: 16.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 18.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6C5CE7).withOpacity(0.15),
                              blurRadius: 15.r,
                              offset: Offset(0, 5.h),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _lastNameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C5CE7),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Last Name',
                            hintStyle: TextStyle(
                              color: const Color(0xFF6C5CE7).withOpacity(0.4),
                              fontSize: 16.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 18.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBirthdayPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.0.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Spacer(flex: 2),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C5CE7).withOpacity(0.3),
                          blurRadius: 15.r,
                          spreadRadius: 3.r,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.cake_rounded,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C5CE7).withOpacity(0.1),
                          blurRadius: 15.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: Text(
                      'When\'s your birthday?',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'We need this to personalize your wellness journey',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF6B8BA8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedDate != null
                              ? const Color(0xFF6C5CE7)
                              : const Color(0xFF6C5CE7).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C5CE7).withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: _selectedDate != null
                                ? const Color(0xFF6C5CE7)
                                : const Color(0xFF6C5CE7).withOpacity(0.5),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _selectedDate == null
                                ? 'Select Your Birthday'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _selectedDate != null
                                  ? const Color(0xFF6C5CE7)
                                  : const Color(0xFF6C5CE7).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF6C5CE7), size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Age: ${DateTime.now().year - _selectedDate!.year} years old',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF667EEA)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 15.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Text(
              'Key Features',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFeatureCard(
                    Icons.mood_rounded,
                    'Track Your Mood',
                    'Log emotions and discover patterns',
                    const Color(0xFF6C5CE7),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.auto_stories_rounded,
                    'Daily Journaling',
                    'Express yourself through writing',
                    const Color(0xFF667EEA),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.emoji_events_rounded,
                    'Achievements & Rewards',
                    'Unlock rewards as you progress',
                    const Color(0xFF9575CD),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.people_rounded,
                    'Social Support',
                    'Connect with friends on the journey',
                    const Color(0xFF64B5F6),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.lock_person_rounded,
                    'Private & Secure',
                    'Your journal entries are private',
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.pets_rounded,
                    'Pet Companion',
                    'Grow a magical pet as you improve',
                    const Color(0xFFFF8A65),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Color(0xFF6B8BA8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSelectionPage() {
    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3)),
            ),
            child: Text(
              'Your companion will reflect your wellness journey',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.75,
              ),
              itemCount: _characterOptions.length,
              itemBuilder: (context, index) {
                final character = _characterOptions[index];
                final isSelected = _selectedCharacterId == character['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCharacterId = character['id'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? character['color']
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? (character['color'] as Color)
                                  .withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Character GIF - using standard Image.asset
                        Flexible(
                          child: Container(
                            width: 85.w,
                            height: 85.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: character['color'], width: 2.w),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(42.5.r),
                              child: Image.asset(
                                character['gifPath'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          character['name'],
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6C5CE7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(
                              character['description'],
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF6B8BA8),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: character['color'],
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
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

  Widget _buildInterestsPage() {
    // Group interests by category
    final Map<String, List<Map<String, dynamic>>> groupedInterests = {};
    for (var interest in _allInterests) {
      final category = interest['category'] ?? 'other';
      if (!groupedInterests.containsKey(category)) {
        groupedInterests[category] = [];
      }
      groupedInterests[category]!.add(interest);
    }

    final categoryNames = {
      'wellness': 'Wellness & Mental Health',
      'creative': 'Creative & Artistic',
      'physical': 'Physical & Active',
      'social': 'Social & Connection',
      'growth': 'Learning & Growth',
      'nature': 'Nature & Outdoors',
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Interests',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select at least 3 interests that resonate with you',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),

          if (_loadingInterests)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.h),
                child: const CircularProgressIndicator(),
              ),
            )
          else if (_allInterests.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.h),
                child: Text(
                  'No interests available',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ...groupedInterests.entries.map((entry) {
              final category = entry.key;
              final interests = entry.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryNames[category] ?? category,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: interests.map((interest) {
                      final isSelected = _selectedInterestIds.contains(interest['id']);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedInterestIds.remove(interest['id']);
                            } else {
                              _selectedInterestIds.add(interest['id']);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF667EEA)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA).withOpacity(0.3),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            interest['name'] ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                ],
              );
            }).toList(),

          SizedBox(height: 16.h),
          
          // Selection count indicator
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _selectedInterestIds.length >= 3
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedInterestIds.length >= 3
                    ? const Color(0xFF667EEA).withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedInterestIds.length >= 3
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedInterestIds.length >= 3
                      ? const Color(0xFF667EEA)
                      : Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _selectedInterestIds.length >= 3
                        ? '${_selectedInterestIds.length} interests selected - Great!'
                        : 'Select at least ${3 - _selectedInterestIds.length} more',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _selectedInterestIds.length >= 3
                          ? const Color(0xFF667EEA)
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 80.h), // Space for bottom navigation
        ],
      ),
    );
  }
}
