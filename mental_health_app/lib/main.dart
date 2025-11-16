import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/character_provider.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mental Health App',
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
