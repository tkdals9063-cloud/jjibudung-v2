import 'package:flutter/material.dart';

import 'calibration_screen.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("자세 준비"), centerTitle: true),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              "기준 자세 측정 시작",
              style: TextStyle(fontSize: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalibrationScreen(),
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                const Icon(
                  Icons.accessibility_new,
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
                  "처음 5초는 휴대폰을 넣는 준비 시간이에요.\n다음 5초에 측정하고 진동으로 완료를 알려드려요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 35),

                _guideTile(Icons.accessibility_new, "바르게 서서 양발을 편하게 놓아주세요."),

                _guideTile(Icons.phone_android, "휴대폰 상단은 아래로, 화면은 몸쪽을 향하게 바지 앞주머니에 넣어주세요."),

                _guideTile(Icons.visibility_off_outlined, "준비 시간이 끝나면 눈을 감고 5초 동안 가만히 서 있어주세요."),

                _guideTile(
                  Icons.vibration,
                  "측정이 끝나면 진동으로 알려드려요.",
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
                              "휴대폰 측정 기준",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "지금은 휴대폰의 앞뒤·좌우 각도로 자세 친구를 추정해요.\n의자 연동 기능이 준비되면 의자 센서 값으로 측정할 예정이에요.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
