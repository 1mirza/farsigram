import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/game_state.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

/// صفحه‌ی لودینگ اول اجرا
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<double> _logoScale =
      CurvedAnimation(parent: _c, curve: Curves.elasticOut);
  late final Animation<double> _fade = CurvedAnimation(
      parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2300), _go);
  }

  void _go() {
    if (!mounted) return;
    final next =
        GameState.onboarded ? const HomeShell() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.nightGradient),
        child: Stack(
          children: [
            const Positioned(
                top: -60,
                right: -40,
                child: _Blob(size: 220, color: AppTheme.primary)),
            const Positioned(
                bottom: -70,
                left: -50,
                child: _Blob(size: 260, color: AppTheme.secondary)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: AppTheme.glow(AppTheme.primary),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          color: Colors.white, size: 58),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: const [
                        Text('پارسی‌گرام ششم',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('فارسی را مثل شبکه‌ی اجتماعی یاد بگیر',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: _fade,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: FadeTransition(
                opacity: _fade,
                child: const Text(
                  'ساخته‌ی حمیدرضا علی میرزائی',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.55), Colors.transparent],
          ),
        ),
      );
}
