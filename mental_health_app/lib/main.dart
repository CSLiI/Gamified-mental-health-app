import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/character_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/pet_provider.dart';
import 'core/router/app_router.dart';
import 'data/services/cache_service.dart';
import 'core/utils/image_cache_manager.dart';

import 'core/providers/notification_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to portrait only for stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize centralized cache service (for all API responses)
  await CacheService().initialize();

  runApp(
    MultiProvider(
      providers: [
        // ThemeProvider first - provides theme data to all screens
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // UserProvider second - provides cached user data to other providers
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Inject UserProvider into other providers to eliminate redundant API calls
        ChangeNotifierProxyProvider<UserProvider, MoodProvider>(
          create: (context) => MoodProvider(context.read<UserProvider>()),
          update: (_, userProvider, moodProvider) =>
              moodProvider ?? MoodProvider(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, CharacterProvider>(
          create: (context) => CharacterProvider(context.read<UserProvider>()),
          update: (_, userProvider, characterProvider) =>
              characterProvider ?? CharacterProvider(userProvider),
        ),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final palette = themeProvider.palette;
        final fontFamily = themeProvider.fontFamily;
        
        // Create text theme using GoogleFonts
        final textTheme = GoogleFonts.getFont(
          fontFamily,
          textStyle: TextStyle(color: palette.textPrimary),
        );

        final isDark = palette.background.computeLuminance() < 0.5;
        final brightness = isDark ? Brightness.dark : Brightness.light;
        final tertiary = palette.accent;
        final onTertiary = tertiary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

        final onPrimary = palette.primary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

        return ScreenUtilInit(
          designSize: const Size(375, 812), // Standard mobile design size
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              title: 'Echo',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme(
                  brightness: brightness,
                  primary: palette.primary,
                  onPrimary: onPrimary,
                  secondary: palette.secondary,
                  onSecondary: Colors.white,
                  tertiary: tertiary,
                  onTertiary: onTertiary,
                  tertiaryContainer: tertiary.withOpacity(0.8),
                  onTertiaryContainer: onTertiary,
                  error: const Color(0xFFE53E3E),
                  onError: Colors.white,
                  background: palette.background,
                  onBackground: palette.textPrimary,
                  surface: palette.surface,
                  onSurface: palette.textPrimary,
                ),
                scaffoldBackgroundColor: palette.background,
                cardColor: palette.surface,
                textTheme: TextTheme(
                  displayLarge: textTheme.copyWith(fontWeight: FontWeight.bold, fontSize: 32.sp),
                  displayMedium: textTheme.copyWith(fontWeight: FontWeight.bold, fontSize: 28.sp),
                  displaySmall: textTheme.copyWith(fontWeight: FontWeight.bold, fontSize: 24.sp),
                  headlineLarge: textTheme.copyWith(fontWeight: FontWeight.bold, fontSize: 22.sp),
                  headlineMedium: textTheme.copyWith(fontWeight: FontWeight.w600, fontSize: 20.sp),
                  headlineSmall: textTheme.copyWith(fontWeight: FontWeight.w600, fontSize: 18.sp),
                  titleLarge: textTheme.copyWith(fontWeight: FontWeight.w600, fontSize: 16.sp),
                  titleMedium: textTheme.copyWith(fontWeight: FontWeight.w600, fontSize: 14.sp),
                  titleSmall: textTheme.copyWith(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  bodyLarge: textTheme.copyWith(fontWeight: FontWeight.normal, fontSize: 16.sp),
                  bodyMedium: textTheme.copyWith(fontWeight: FontWeight.normal, fontSize: 14.sp),
                  bodySmall: textTheme.copyWith(fontWeight: FontWeight.normal, fontSize: 12.sp),
                  labelLarge: textTheme.copyWith(fontWeight: FontWeight.w600, fontSize: 14.sp),
                  labelMedium: textTheme.copyWith(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  labelSmall: textTheme.copyWith(fontWeight: FontWeight.w500, fontSize: 10.sp),
                ),
              ),
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
