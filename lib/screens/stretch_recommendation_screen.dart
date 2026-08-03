import 'package:flutter/material.dart';

class StretchRecommendationScreen extends StatelessWidget {
  const StretchRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stretches = [
      ('목 앞쪽 이완', '고개를 천천히 뒤로 젖혀 목 앞쪽을 부드럽게 늘려주세요.', '30초'),
      ('가슴 열기', '양손을 등 뒤에서 잡고 가슴을 가볍게 열어주세요.', '30초'),
      ('장요근 스트레칭', '한쪽 무릎을 바닥에 대고 골반을 천천히 앞으로 밀어요.', '양쪽 30초'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('FLS-A 추천 스트레칭')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffF5F1FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '🐢 거북목 탐험가와 🦊 앞기울임 여우를 위한\n5분 자세 리셋 루틴이에요.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...stretches.asMap().entries.map((entry) {
            final stretch = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor: Colors.grey.shade100,
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(
                  stretch.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${stretch.$2}\n${stretch.$3}'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
