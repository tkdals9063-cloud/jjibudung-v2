import 'package:flutter/material.dart';

import 'calibration_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});
  Future<bool> _requestNotificationPermission(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    final currentStatus = await Permission.notification.status;

    if (currentStatus.isGranted) {
      return true;
    }

    if (!context.mounted) return false;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('백그라운드 자세 측정 권한'),
          content: const Text(
            '앱을 나가도 자세 측정을 계속하고, '
            '상단 알림에 측정 시간을 표시하려면 알림 권한이 필요해요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('권한 허용하기'),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) return false;

    final result = await Permission.notification.request();

    if (result.isGranted) return true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 권한을 허용하면 백그라운드 측정이 가능해요.')),
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("자세 준비"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                const Icon(
                  Icons.self_improvement,
                  size: 90,
                  color: Color(0xff725AC1),
                ),

                const SizedBox(height: 20),

                const Text(
                  "자세를 준비해주세요",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "정확한 측정을 위해\n아래 내용을 확인해주세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 35),

                _guideTile(Icons.chair_alt, "허리를 곧게 펴고 의자 깊숙이 앉아주세요."),

                _guideTile(Icons.phone_android, "휴대폰을 바지 앞주머니에 넣어주세요."),

                _guideTile(Icons.accessibility_new, "양발은 바닥에 편하게 놓아주세요."),

                _guideTile(
                  Icons.sentiment_satisfied_alt,
                  "어깨에 힘을 빼고 자연스럽게 앉아주세요.",
                ),

                const SizedBox(height: 30),

                Card(
                  color: const Color(0xffF6F2FF),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber),

                            SizedBox(width: 8),

                            Text(
                              "왜 주머니에 넣나요?",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "휴대폰이 몸과 가까울수록\n몸의 기울기를 더 정확하게 측정할 수 있습니다.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "기준 자세 측정 시작",
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: () async {
                      final allowed = await _requestNotificationPermission(
                        context,
                      );

                      if (!allowed || !context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalibrationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guideTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff725AC1), size: 28),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
