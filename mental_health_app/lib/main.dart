import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/character_provider.dart';
import 'core/router/app_router.dart';
import 'data/services/cache_service.dart';
import 'core/utils/image_cache_manager.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize centralized cache service (for all API responses)
  await CacheService().initialize();

  runApp(
    MultiProvider(
      providers: [
        // UserProvider first - provides cached user data to other providers
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload character GIFs on app start (all screens will be faster)
    ImageCacheManager().preloadCharacterAssets(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Echo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5CACEE),
        ),
        useMaterial3: true,
        // Apply Nunito font globally - perfect for gamified mental health app
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          displaySmall:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          headlineLarge:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          titleSmall:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500),
          bodyLarge:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.normal),
          bodyMedium:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.normal),
          bodySmall:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.normal),
          labelLarge:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          labelMedium:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500),
          labelSmall:
              TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
