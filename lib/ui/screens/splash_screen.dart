import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/radio_provider.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);

    // Give the splash screen animations time to run, and wait for RadioProvider initialization
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2200)),
      _waitForInitialization(radioProvider),
    ]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _waitForInitialization(RadioProvider provider) async {
    if (provider.isInitialized) return;
    // Wait until initialized or times out
    int elapsed = 0;
    while (!provider.isInitialized && elapsed < 8000) {
      await Future.delayed(const Duration(milliseconds: 100));
      elapsed += 100;
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E1E38), AppTheme.background],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow backdrops
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryStart.withValues(alpha: 0.08),
                ),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.02),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryStart.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const ShaderMask(
                      shaderCallback: _createGradientShader,
                      child: Icon(Icons.radio, size: 80, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(opacity: _fadeAnimation.value, child: child);
                  },
                  child: Column(
                    children: [
                      Text(
                        'LABHOUSE FM',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 26,
                              letterSpacing: 8.0,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'P R E M I U M   R A D I O   T U N E R',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 10,
                          color: AppTheme.primaryStart,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom Loading Indicator
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryStart,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resolving radio nodes...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Workaround for some Flutter platform engines
  static Shader _createGradientShader(Rect bounds) {
    return AppTheme.primaryGradient.createShader(bounds);
  }
}
