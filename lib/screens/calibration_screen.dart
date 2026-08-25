import 'dart:async';

import 'package:flutter/material.dart';

import '../services/native_posture_service.dart';
import '../services/storage_service.dart';
import 'work_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  static const int calibrationSeconds = 5;

  int _count = calibrationSeconds;
  Timer? _timer;
  StreamSubscription<PostureAngles>? _angleSubscription;
  final List<double> _pitches = [];
  final List<double> _rolls = [];
  bool _hasSensorError = false;

  @override
  void initState() {
    super.initState();
    _startCalibration();
  }

  Future<void> _startCalibration() async {
    _angleSubscription = NativePostureService.angleStream.listen(
      (angles) {
        _pitches.add(angles.pitch);
        _rolls.add(angles.roll);
      },
      onError: (_) {
        if (mounted) setState(() => _hasSensorError = true);
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_count != 1) {
        if (mounted) setState(() => _count--);
        return;
      }

      timer.cancel();
      await _angleSubscription?.cancel();

      if (_pitches.isEmpty || _rolls.isEmpty) {
        if (mounted) setState(() => _hasSensorError = true);
        return;
      }

      final baselinePitch = _pitches.reduce((a, b) => a + b) / _pitches.length;
      final baselineRoll = _rolls.reduce((a, b) => a + b) / _rolls.length;

      await StorageService.saveInitialPostureProfile(
        baselineAngle: baselinePitch,
        baselineRoll: baselineRoll,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkScreen(
            baselinePitch: baselinePitch,
            baselineRoll: baselineRoll,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _angleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자세 보정'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _hasSensorError
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_off_outlined, size: 72),
                    SizedBox(height: 20),
                    Text(
                      '센서 값을 읽지 못했어요.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '휴대폰 위치를 확인한 뒤 다시 시도해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.accessibility_new, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      '바른 자세를 유지해주세요.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '앞뒤와 좌우 기준 자세를 측정 중입니다.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '$_count',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ),
        ),
      ),
    );
  }
}
