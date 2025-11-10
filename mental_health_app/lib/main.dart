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
      ),
      routerConfig: appRouter,
    );
  }
}
