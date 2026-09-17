import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../services/phone_angle_companion_classifier.dart';
import '../services/native_posture_service.dart';
import '../services/storage_service.dart';
import 'work_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  static const int preparationSeconds = 5;
  static const int calibrationSeconds = 5;

  int _count = preparationSeconds;
  _CalibrationPhase _phase = _CalibrationPhase.preparing;
  Timer? _timer;
  StreamSubscription<PostureAngles>? _angleSubscription;
  final List<double> _pitches = [];
  final List<double> _rolls = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPreparation();
  }

  void _startPreparation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_count > 1) {
        setState(() => _count--);
        return;
      }
      if (_phase == _CalibrationPhase.preparing) {
        _beginMeasurement();
      } else if (_phase == _CalibrationPhase.measuring) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _beginMeasurement() {
    setState(() {
      _phase = _CalibrationPhase.measuring;
      _count = calibrationSeconds;
    });
    _angleSubscription = NativePostureService.angleStream.listen(
      (angles) {
        if (angles.pitch.isFinite && angles.roll.isFinite) {
          _pitches.add(angles.pitch);
          _rolls.add(angles.roll);
        }
      },
      onError: (_) {
        _timer?.cancel();
        if (mounted) {
          setState(() => _errorMessage = '센서 값을 읽지 못했어요.');
        }
      },
    );
  }

  Future<void> _finishMeasurement() async {
    await _angleSubscription?.cancel();
    if (!mounted || _errorMessage != null) return;
    if (_pitches.isEmpty || _rolls.isEmpty) {
      setState(() => _errorMessage = '센서 값을 읽지 못했어요.');
      return;
    }
    setState(() => _phase = _CalibrationPhase.saving);
    try {
      final baselinePitch = _median(_pitches);
      final baselineRoll = _median(_rolls);
      final selection = PhoneAngleCompanionClassifier.fromAngles(
        pitch: baselinePitch,
        roll: baselineRoll,
      );
      await _notifyMeasurementComplete();
      await StorageService.saveInitialPostureProfile(
        baselineAngle: baselinePitch,
        baselineRoll: baselineRoll,
        selection: selection,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkScreen(
            baselinePitch: baselinePitch,
            baselineRoll: baselineRoll,
            selection: selection,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '측정 결과를 저장하지 못했어요. 다시 시도해주세요.');
      }
    }
  }

  Future<void> _notifyMeasurementComplete() async {
    try {
      if (!await StorageService.loadVibrationEnabled()) return;
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 450);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // 진동 장치가 없어도 측정 결과 저장은 계속한다.
    }
  }

  double _median(List<double> samples) {
    final sorted = [...samples]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
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
          child: _errorMessage != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sensors_off_outlined, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pitches.isEmpty
                          ? '휴대폰 위치를 확인한 뒤 다시 시도해주세요.'
                          : '잠시 후 다시 시도해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.accessibility_new, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      switch (_phase) {
                        _CalibrationPhase.preparing => '휴대폰을 주머니에 넣어주세요.',
                        _CalibrationPhase.measuring => '바르게 서서 눈을 감아주세요.',
                        _CalibrationPhase.saving => '측정이 완료됐어요.',
                      },
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch (_phase) {
                        _CalibrationPhase.preparing => '준비 시간 5초 · 아직 측정하지 않아요.',
                        _CalibrationPhase.measuring => '5초 동안 움직이지 않고 각도를 측정해요.',
                        _CalibrationPhase.saving => '결과를 저장하고 있어요.',
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _phase == _CalibrationPhase.saving ? '완료' : '$_count',
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

enum _CalibrationPhase { preparing, measuring, saving }
