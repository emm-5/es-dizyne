import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  void _navigate() {
    if (mounted) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESDizyneTheme.darkBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: ESDizyneGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ESDizyneTheme.primary.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('ES', style: TextStyle(
                        color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.bold, letterSpacing: 2,
                      )),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => ESDizyneGradients.primaryGradient.createShader(bounds),
                    child: const Text('ES Dizyne', style: TextStyle(
                      color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                    )),
                  ),
                  const SizedBox(height: 8),
                  const Text('Professional Mobile Design Suite', style: TextStyle(
                    color: ESDizyneTheme.textMuted, fontSize: 13, letterSpacing: 1,
                  )),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      backgroundColor: ESDizyneTheme.darkBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(ESDizyneTheme.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
