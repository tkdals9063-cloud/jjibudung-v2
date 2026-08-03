import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> pages = const [
    _OnboardingData(
      icon: Icons.menu_book_rounded,
      title: '환영합니다!',
      description: '휴대폰을 바지 앞주머니에 넣으면\n앉아 있는 동안의 자세를 감지해\n바른 자세를 도와드려요.',
    ),
    _OnboardingData(
      icon: Icons.phone_android_rounded,
      title: '일상 속 자세 측정',
      description: '휴대폰을 바지 앞주머니에 넣으면\n앉아 있는 동안의 자세를 감지해\n바른 자세를 도와드려요.',
    ),
    _OnboardingData(
      icon: Icons.accessibility_new_rounded,
      title: '이제 준비됐어요',
      description: '작은 바른 자세가\n하루의 집중을 바꿔요.\n\n우리, 지금부터\n바른 자세를 시작해요.',
    ),
  ];

  Future<void> _nextPage() async {
    if (_currentPage != pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xff725AC1),
                          child: Icon(page.icon, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xff725AC1)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == pages.length - 1 ? '시작하기' : '다음',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
