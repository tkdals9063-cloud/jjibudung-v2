import 'package:flutter/material.dart';

import 'core/app_tab_controller.dart';
import 'screens/played_screen.dart';
import 'screens/posture_profile_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  static const List<Widget> _screens = [
    WelcomeScreen(),
    PlayedScreen(),
    PostureProfileScreen(),
    RewardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTabController.currentIndex,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => AppTabController.currentIndex.value = index,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
              BottomNavigationBarItem(
                icon: Icon(Icons.accessibility_new),
                label: '스트레칭',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: '상점'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            ],
          ),
        );
      },
    );
  }
}
