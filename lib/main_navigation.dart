import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/played_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WelcomeScreen(),
    const PlayedScreen(),

    const Center(child: Text("스트레칭", style: TextStyle(fontSize: 24))),

    const Center(child: Text("설정", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),

          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "통계"),

          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: "스트레칭",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "설정"),
        ],
      ),
    );
  }
}
