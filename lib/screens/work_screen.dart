import 'dart:async';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/formatter.dart';
import 'result_screen.dart';

/// 휴대폰 단독 모드에서는 자세를 실시간 판정하지 않고 시간만 기록한다.
/// baselinePitch / baselineRoll은 기존 보정 화면과의 호환을 위해 유지한다.
class WorkScreen extends StatefulWidget {
  final double? baselinePitch;
  final double? baselineRoll;

  const WorkScreen({super.key, this.baselinePitch, this.baselineRoll});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  Timer? _timer;
  int _totalSeconds = 0;
  bool _isFinishing = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _totalSeconds++);
    });
  }

  void _togglePause() {
    if (_isFinishing) return;

    setState(() => _isPaused = !_isPaused);

    if (_isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  Future<void> _finishWork() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);
    _timer?.cancel();

    // 휴대폰 단독 모드에는 실제 자세 판정값을 저장하지 않는다.
    await StorageService.saveStudyResult(
      studySeconds: _totalSeconds,
      goodPostureSeconds: 0,
      earnedPoint: 0,
      postureRate: 0,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          totalSeconds: _totalSeconds,
          goodSeconds: 0,
          badSeconds: 0,
          postureRate: 0,
          earnedPoint: 0,
          isTimeOnly: true,
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
      appBar: AppBar(title: const Text('시간 기록 중'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.timer_outlined,
                size: 88,
                color: Color(0xff725AC1),
              ),
              const SizedBox(height: 24),
              const Text(
                '집중 시간을 기록하고 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '휴대폰 단독 모드에서는 자세를 실시간으로 판정하지 않아요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              Text(
                Formatter.formatTime(_totalSeconds),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isPaused ? '기록을 잠시 멈췄어요' : '기록 중',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isPaused ? Colors.orange : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                '의자 연동 후 자세 분석 기능을 사용할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _isFinishing ? null : _togglePause,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(_isPaused ? '기록 재개' : '일시정지'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isFinishing ? null : _finishWork,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('기록 종료'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
