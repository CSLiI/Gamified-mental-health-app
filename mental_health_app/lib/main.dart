import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mental Health App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, // Changed from AppTheme.primaryLight (which is a Color, not ThemeData)
      routerConfig: AppRouter.router,
    );
  }
}