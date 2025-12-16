import 'package:go_router/go_router.dart';
import 'navigation_service.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/home/home_navigation.dart';
import '../../presentation/screens/social/social_screen.dart';
import '../../presentation/screens/social/friend_profile_screen.dart';
import '../../presentation/screens/social/notifications_screen.dart';
import '../../presentation/screens/journal/journal_screen.dart';
import '../../presentation/screens/todos/todo_screen.dart';
import '../../presentation/screens/pets/pet_care_screen.dart';

final appRouter = GoRouter(
  navigatorKey: NavigationService.navigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ResetPasswordScreen(token: token);
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        registrationData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialIndex = extra?['initialIndex'] as int? ?? 0;
        final initialTabIndex = extra?['initialTabIndex'] as int? ?? 0;
        return HomeNavigation(
          initialIndex: initialIndex,
          initialTabIndex: initialTabIndex,
        );
      },
    ),
    GoRoute(
      path: '/social',
      builder: (context, state) => const SocialScreen(),
    ),
    GoRoute(
      path: '/journal',
      builder: (context, state) => const JournalScreen(),
    ),
    GoRoute(
      path: '/todos',
      builder: (context, state) => const TodoScreen(),
    ),
    GoRoute(
      path: '/friend/:id',
      builder: (context, state) {
        final friendId = int.parse(state.pathParameters['id']!);
        final friendName = state.uri.queryParameters['name'] ?? 'Friend';
        return FriendProfileScreen(
          friendId: friendId,
          friendName: friendName,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/pet-care',
      builder: (context, state) => const PetCareScreen(),
    ),
  ],
);
