import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_navigation.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    // 스플래시 화면을 잠시 보여 주는 동안 최초 실행 여부를 불러온다.
    await Future<void>.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasSeenOnboarding
            ? const MainNavigation()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff725AC1), Color(0xff8A73D6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.self_improvement,
                  color: Colors.white,
                  size: 90,
                ),
                const SizedBox(height: 30),
                const Text(
                  '찌뿌둥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '오늘도 바른 자세로,\n더 오래 집중하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 70),
                const SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}