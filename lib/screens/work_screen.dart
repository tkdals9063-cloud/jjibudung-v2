import 'dart:async';

import 'package:flutter/material.dart';

import '../services/native_posture_service.dart';
import '../services/storage_service.dart';
import '../utils/formatter.dart';
import 'result_screen.dart';

class WorkScreen extends StatefulWidget {
  final double baselineAngle;

  const WorkScreen({super.key, required this.baselineAngle});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  Timer? _timer;
  static const double angleThreshold = 15.0;

  int _totalSeconds = 0;
  int _badSeconds = 0;
  double _currentAngle = 0.0;
  double _postureRate = 100.0;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _startWork();
  }

  Future<void> _startWork() async {
    final started = await NativePostureService.start(
      baselineAngle: widget.baselineAngle,
      angleThreshold: angleThreshold,
    );

    if (!started) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자세 측정을 시작할 수 없습니다.')));
      return;
    }

    await _refreshSession();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshSession(),
    );
  }

  Future<void> _refreshSession() async {
    final session = await NativePostureService.getSessionData();
    if (session == null || !mounted) return;

    setState(() {
      _totalSeconds = (session['totalSeconds'] as num?)?.toInt() ?? 0;
      _badSeconds = (session['badSeconds'] as num?)?.toInt() ?? 0;
      _currentAngle = (session['currentAngle'] as num?)?.toDouble() ?? 0.0;
      _postureRate = (session['postureRate'] as num?)?.toDouble() ?? 100.0;
    });
  }

  Future<void> _finishWork() async {
    if (_isFinishing) return;
    _isFinishing = true;
    _timer?.cancel();

    final session = await NativePostureService.getSessionData();
    final total = (session?['totalSeconds'] as num?)?.toInt() ?? _totalSeconds;
    final bad = (session?['badSeconds'] as num?)?.toInt() ?? _badSeconds;
    final good = (session?['goodSeconds'] as num?)?.toInt() ?? (total - bad);
    final postureRate =
        (session?['postureRate'] as num?)?.toDouble() ?? _postureRate;
    final earnedPoint = good ~/ 60;

    await NativePostureService.stop();

    await StorageService.saveStudyResult(
      studySeconds: total,
      goodPostureSeconds: good,
      earnedPoint: earnedPoint,
      postureRate: postureRate,
    );
    await StorageService.updatePostureProfileFromRate(postureRate: postureRate);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          totalSeconds: total,
          goodSeconds: good,
          badSeconds: bad,
          postureRate: postureRate,
          earnedPoint: earnedPoint,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('측정 중'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('현재 각도', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      '${_currentAngle.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('측정 시간'),
                trailing: Text(Formatter.formatTime(_totalSeconds)),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('좋은 자세'),
                trailing: Text('${_postureRate.toStringAsFixed(1)}%'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('나쁜 자세'),
                trailing: Text(
                  '${(100 - _postureRate).clamp(0, 100).toStringAsFixed(1)}%',
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('기준 각도'),
                trailing: Text('${widget.baselineAngle.toStringAsFixed(1)}°'),
              ),
            ),
            const Spacer(),
            const Text(
              '뒤로가기를 눌러도 측정은 계속돼요.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isFinishing ? null : _finishWork,
                icon: const Icon(Icons.stop),
                label: const Text('근무 종료', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
