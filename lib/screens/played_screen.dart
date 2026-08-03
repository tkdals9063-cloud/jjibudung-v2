import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class PlayedScreen extends StatefulWidget {
  const PlayedScreen({super.key});

  @override
  State<PlayedScreen> createState() => _PlayedScreenState();
}

class _PlayedScreenState extends State<PlayedScreen> {
  int _point = 0;
  int _todayStudyTime = 0;
  int _totalStudyTime = 0;
  int _streak = 0;
  double _postureRate = 100.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final point = await StorageService.loadPoint();
    final today = await StorageService.loadTodayStudyTime();
    final total = await StorageService.loadTotalStudyTime();
    final streak = await StorageService.loadStreak();
    final postureRate = await StorageService.loadPostureRate();

    if (!mounted) return;

    setState(() {
      _point = point;
      _todayStudyTime = today;
      _totalStudyTime = total;
      _streak = streak;
      _postureRate = postureRate;
    });
  }

  String getLevel() {
    if (_point >= 1500) {
      return "Lv.5 마스터";
    } else if (_point >= 700) {
      return "Lv.4 고인물";
    } else if (_point >= 300) {
      return "Lv.3 중수";
    } else if (_point >= 100) {
      return "Lv.2 초보자";
    } else {
      return "Lv.1 슬라임";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 통계"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text("현재 포인트"),
              trailing: Text("$_point pt"),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text("현재 레벨"),
              trailing: Text(getLevel()),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text("오늘 공부시간"),
              trailing: Text(
                Duration(seconds: _todayStudyTime).toString().split('.').first,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: const Text("누적 공부시간"),
              trailing: Text(
                Duration(seconds: _totalStudyTime).toString().split('.').first,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text("평균 자세 유지율"),
              trailing: Text("${_postureRate.toStringAsFixed(1)}%"),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.local_fire_department,
                color: Colors.red,
              ),
              title: const Text("연속 공부"),
              trailing: Text("$_streak일"),
            ),
          ),
        ],
      ),
    );
  }
}
