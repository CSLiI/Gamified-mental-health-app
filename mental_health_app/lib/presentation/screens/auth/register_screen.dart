import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'dart:math' as math;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animController;
  int _currentStep = 0;
  final int _totalSteps = 4; // 5 steps total (0-4)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 13)), // Must be 13+ years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gamePurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textTheme: const TextTheme(
              // Set font family to Roboto
              bodyMedium: TextStyle(fontFamily: 'Roboto'),
              bodyLarge: TextStyle(fontFamily: 'Roboto'),
              titleMedium: TextStyle(fontFamily: 'Roboto'),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your character type'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your magical passwords don\'t match!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Register with all required fields
      final response = await _apiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: _selectedDate!.toIso8601String().split('T')[0],
        gender: _selectedGender!,
      );

      print('✅ Registration successful');

      // Login to get token
      await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go('/onboarding');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _animController.forward(from: 0.0);
    } else {
      _register();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animController.forward(from: 0.0);
    } else {
      context.go('/login');
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return "Hero's Name";
      case 1:
        return "Contact Scroll";
      case 2:
        return "Birth Date";
      case 3:
        return "Character Type";
      case 4:
        return "Secret Password";
      default:
        return "Create Character";
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: const TextStyle(
                  color: Color(0xFF0A4B80),
                ),
                prefixIcon:
                    const Icon(Icons.person_outlined, color: Color(0xFF5CACEE)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF5CACEE), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(
                color: Color(0xFF0A4B80),
                fontSize: 16,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter your hero\'s last name',
                prefixIcon: const Icon(Icons.person_outlined,
                    color: AppColors.gamePurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Magical Email',
                hintText: 'Where to send magical notifications',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.gamePurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined,
                        color: AppColors.gamePurple),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Choose Your Birth Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: _selectedDate == null
                            ? Colors.grey
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your age determines your starting abilities',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                dropdownColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Character Type',
                  labelStyle: TextStyle(
                    fontFamily: 'Roboto',
                  ),
                  prefixIcon: Icon(Icons.category_outlined,
                      color: AppColors.gamePurple),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: AppColors.textPrimary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(
                      'Warrior (Male)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(
                      'Sorceress (Female)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(
                      'Mystic (Other)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your character type influences your journey',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Secret Password',
                hintText: 'Create a powerful password',
                prefixIcon: const Icon(Icons.lock_outlined,
                    color: AppColors.gamePurple),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.gameBlue,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your magical password',
                prefixIcon: const Icon(Icons.lock_outlined,
                    color: AppColors.gamePurple),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.gameBlue,
                  ),
                  onPressed: () {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                return null;
              },
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // Full screen coverage
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Using the softer gradient from app_colors
          gradient: AppColors.pastelsGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textPrimary),
                          onPressed: _prevStep,
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / (_totalSteps + 1),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            color: AppColors.gamePurple,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentStep + 1}/${_totalSteps + 1}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Step ${_currentStep + 1} of creating your hero',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Animated step content
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero)
                                .animate(
                              CurvedAnimation(
                                parent: _animController,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: _buildStepContent(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Action buttons
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gamePurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.gamePurple.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep < _totalSteps
                                  ? 'CONTINUE QUEST'
                                  : 'CREATE HERO',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    if (_currentStep == 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have a character? ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: AppColors.gamePurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
