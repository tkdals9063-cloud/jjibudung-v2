import 'package:flutter/material.dart';
import '../main_navigation.dart';
import '../utils/formatter.dart';

class ResultScreen extends StatelessWidget {
  final int totalSeconds;
  final int goodSeconds;
  final int badSeconds;
  final double postureRate;
  final int earnedPoint;

  const ResultScreen({
    super.key,
    required this.totalSeconds,
    required this.goodSeconds,
    required this.badSeconds,
    required this.postureRate,
    required this.earnedPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("오늘의 결과"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),

            const SizedBox(height: 20),

            const Text(
              "오늘도 수고하셨습니다!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("총 공부시간"),
                trailing: Text(Formatter.formatTime(totalSeconds)),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text("좋은 자세"),
                trailing: Text(Formatter.formatTime(goodSeconds)),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.warning),
                title: const Text("나쁜 자세"),
                trailing: Text(Formatter.formatTime(badSeconds)),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: const Text("좋은 자세 유지율"),
                trailing: Text("${postureRate.toStringAsFixed(1)}%"),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.stars),
                title: const Text("획득 포인트"),
                trailing: Text(
                  "+$earnedPoint pt",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: StretchScreen 이동
                },
                icon: const Icon(Icons.self_improvement),
                label: const Text("스트레칭 하기"),
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
                label: const Text("홈으로"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
