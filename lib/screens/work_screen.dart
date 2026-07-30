import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/posture_controller.dart';
import '../services/native_posture_service.dart';
import '../utils/formatter.dart';

class WorkScreen extends StatefulWidget {
  final double baselineAngle;

  const WorkScreen({
    super.key,
    required this.baselineAngle,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final PostureController controller = PostureController();

  Timer? _timer;

static const double angleThreshold = 15.0;

void _onControllerChanged() {
  if (mounted) {
    setState(() {});
  }
}

  @override
void initState() {
  super.initState();

  controller.addListener(_onControllerChanged);

  _startWork();
}

  Future<void> _startWork() async {
    controller.startWork(
      baselineAngle: widget.baselineAngle,
    );

final started = await NativePostureService.start(    
  baselineAngle: widget.baselineAngle,
  angleThreshold: angleThreshold,
);

if (!started) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("자세 측정을 시작할 수 없습니다."),
    ),
  );
  return;
}

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        final angle =
    await NativePostureService.getCurrentAngle();

if (!angle.isFinite) return;

        controller.updateAngle(
  angle: angle,
  angleThreshold: angleThreshold,
);

controller.tick(
  angleThreshold: angleThreshold,
);

        if (controller.shouldVibrate()) {
          HapticFeedback.heavyImpact();
        }
      },
    );
  }

  Future<void> _finishWork() async {
    _timer?.cancel();

    await NativePostureService.stop();

    controller.stopWork();

    if (!mounted) return;

    // TODO :
    // ResultScreen 완성 후 이동
  }

 @override
void dispose() {
  _timer?.cancel();

  controller.removeListener(_onControllerChanged);

  controller.dispose();

  super.dispose();
}

@override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("근무 중"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "현재 각도",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${controller.data.currentAngle.toStringAsFixed(1)}°",
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
                title: const Text("총 작업시간"),
                trailing: Text(
                  Formatter.formatTime(
  controller.data.totalSeconds,
),
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text("좋은 자세"),
                trailing: Text(
                  "${controller.data.postureRate.toStringAsFixed(1)}%",
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.warning),
                title: const Text("나쁜 자세"),
                trailing: Text(
                  "${controller.data.badPostureRate.toStringAsFixed(1)}%",
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text("기준 각도"),
                trailing: Text(
                  "${controller.data.baselineAngle.toStringAsFixed(1)}°",
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _finishWork,
                icon: const Icon(Icons.stop),
                label: const Text(
                  "근무 종료",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}