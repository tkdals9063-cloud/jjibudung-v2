import 'dart:async';

import 'package:flutter/material.dart';

import 'work_screen.dart';
import '../services/native_posture_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  static const int calibrationSeconds = 5;

  int _count = calibrationSeconds;
  Timer? _timer;

  final List<double> _angles = [];

  @override
  void initState() {
    super.initState();
    _startCalibration();
  }

  Future<void> _startCalibration() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final angle = await NativePostureService.getCurrentAngle();
      _angles.add(angle);

      if (_count == 1) {
        timer.cancel();

        final baseline =
            _angles.reduce((a, b) => a + b) / _angles.length;

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkScreen(
              baselineAngle: baseline,
            ),
          ),
        );

        return;
      }

      setState(() {
        _count--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("자세 보정"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.accessibility_new,
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                "바른 자세를 유지해주세요.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "기준 자세를 측정 중입니다.",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 40),

              Text(
                "$_count",
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