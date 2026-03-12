import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class ESDizyneApp extends StatelessWidget {
  const ESDizyneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ES Dizyne',
      debugShowCheckedModeBanner: false,
      theme: ESDizyneTheme.lightTheme,
      darkTheme: ESDizyneTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
