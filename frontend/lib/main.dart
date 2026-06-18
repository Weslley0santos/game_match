import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/games/screens/games_screen.dart';
import 'features/swipe/screens/swipe_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Match',
      theme: AppTheme.darkTheme,

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/swipe': (context) => const SwipeScreen(),
        '/games': (context) => const GamesScreen(),
      },
    );
  }
}
