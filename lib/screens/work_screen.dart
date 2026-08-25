import 'dart:async';

import 'package:flutter/material.dart';

import '../services/native_posture_service.dart';
import '../services/storage_service.dart';
import '../utils/formatter.dart';
import 'result_screen.dart';

class WorkScreen extends StatefulWidget {
  final double baselinePitch;
  final double baselineRoll;

  const WorkScreen({
    super.key,
    required this.baselinePitch,
    required this.baselineRoll,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  static const double pitchThreshold = 15.0;
  static const double rollThreshold = 10.0;

  Timer? _timer;

  int _totalSeconds = 0;
  int _badSeconds = 0;

  double _currentPitch = 0.0;
  double _currentRoll = 0.0;
  double _rollDeviation = 0.0;
  double _postureRate = 100.0;

  bool _isSidewaysBad = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _startWork();
  }

  Future<void> _startWork() async {
    final started = await NativePostureService.start(
      baselinePitch: widget.baselinePitch,
      baselineRoll: widget.baselineRoll,
      pitchThreshold: pitchThreshold,
      rollThreshold: rollThreshold,
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
      _currentPitch = (session['currentPitch'] as num?)?.toDouble() ?? 0.0;
      _currentRoll = (session['currentRoll'] as num?)?.toDouble() ?? 0.0;
      _rollDeviation = (session['rollDeviation'] as num?)?.toDouble() ?? 0.0;
      _postureRate = (session['postureRate'] as num?)?.toDouble() ?? 100.0;
      _isSidewaysBad = session['isSidewaysBad'] as bool? ?? false;
    });
  }

  Future<void> _finishWork() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);
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
    final sideStatus = _isSidewaysBad ? '좌우 쏠림 감지' : '좌우 균형 안정';
    final sideColor = _isSidewaysBad ? Colors.orange : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('측정 중'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('현재 앞뒤 기울기', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      '${_currentPitch.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.swap_horiz_rounded, color: sideColor),
                title: const Text('현재 좌우 기울기'),
                subtitle: Text('기준에서 ${_rollDeviation.toStringAsFixed(1)}° 변화'),
                trailing: Text(
                  '${_currentRoll.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: sideColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.balance_rounded, color: sideColor),
                title: const Text('좌우 균형'),
                trailing: Text(
                  sideStatus,
                  style: TextStyle(
                    color: sideColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                title: const Text('기준 앞뒤 각도'),
                trailing: Text('${widget.baselinePitch.toStringAsFixed(1)}°'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('기준 좌우 각도'),
                trailing: Text('${widget.baselineRoll.toStringAsFixed(1)}°'),
              ),
            ),
            const SizedBox(height: 32),
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
