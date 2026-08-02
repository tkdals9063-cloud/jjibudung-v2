import 'package:flutter/material.dart';

import 'calibration_screen.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("자세 준비"),
        centerTitle: true,
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
                Icons.self_improvement,
                size: 90,
                color: Color(0xff725AC1),
              ),

              const SizedBox(height: 20),

              const Text(
                "자세를 준비해주세요",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "정확한 측정을 위해\n아래 내용을 확인해주세요.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 35),

              _guideTile(
                Icons.chair_alt,
                "허리를 곧게 펴고 의자 깊숙이 앉아주세요.",
              ),

              _guideTile(
                Icons.phone_android,
                "휴대폰을 바지 앞주머니에 넣어주세요.",
              ),

              _guideTile(
                Icons.accessibility_new,
                "양발은 바닥에 편하게 놓아주세요.",
              ),

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

                          Icon(
                            Icons.lightbulb,
                            color: Colors.amber,
                          ),

                          SizedBox(width: 8),

                          Text(
                            "왜 주머니에 넣나요?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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

          Icon(
            icon,
            color: const Color(0xff725AC1),
            size: 28,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}