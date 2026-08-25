import 'package:flutter/material.dart';

import '../core/app_tab_controller.dart';
import '../main_navigation.dart';
import '../utils/formatter.dart';

class ResultScreen extends StatelessWidget {
  final int totalSeconds;
  final int goodSeconds;
  final int badSeconds;
  final double postureRate;
  final int earnedPoint;
  final bool isTimeOnly;

  const ResultScreen({
    super.key,
    required this.totalSeconds,
    required this.goodSeconds,
    required this.badSeconds,
    required this.postureRate,
    required this.earnedPoint,
    this.isTimeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 결과'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              isTimeOnly ? '시간 기록을 완료했어요!' : '오늘도 수고하셨습니다!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('총 기록 시간'),
                trailing: Text(Formatter.formatTime(totalSeconds)),
              ),
            ),
            if (isTimeOnly)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.chair_alt_outlined),
                  title: Text('자세 분석'),
                  subtitle: Text('찌뿌둥 체어 연동 후 확인할 수 있어요.'),
                  trailing: Icon(Icons.lock_outline),
                ),
              )
            else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('좋은 자세'),
                  trailing: Text(Formatter.formatTime(goodSeconds)),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning),
                  title: const Text('나쁜 자세'),
                  trailing: Text(Formatter.formatTime(badSeconds)),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('좋은 자세 유지율'),
                  trailing: Text('${postureRate.toStringAsFixed(1)}%'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.stars),
                  title: const Text('획득 포인트'),
                  trailing: Text(
                    '+$earnedPoint pt',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppTabController.currentIndex.value = 2;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.self_improvement),
                label: const Text('내 자세 친구 보기'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('홈으로'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
