import 'package:flutter/material.dart';

class StretchRecommendationScreen extends StatelessWidget {
  final String profileId;

  const StretchRecommendationScreen({super.key, this.profileId = 'balanced'});

  @override
  Widget build(BuildContext context) {
    final recommendation = switch (profileId) {
      'forward' => const _Recommendation(
        title: 'FLS-A 추천 스트레칭',
        message: '🐢 거북목 탐험가와 🦊 앞기울임 여우를 위한\n5분 자세 리셋 루틴이에요.',
        stretches: [
          ('목 앞쪽 이완', '고개를 천천히 뒤로 젖혀 목 앞쪽을 부드럽게 늘려주세요.', '30초'),
          ('가슴 열기', '양손을 등 뒤에서 잡고 가슴을 가볍게 열어주세요.', '30초'),
          ('장요근 스트레칭', '한쪽 무릎을 바닥에 대고 골반을 천천히 앞으로 밀어요.', '양쪽 30초'),
        ],
      ),
      'slouch' => const _Recommendation(
        title: 'SSS-P 추천 스트레칭',
        message: '🐻 꾸벅 곰과 🦔 말린 고슴도치를 위한\n등·골반 펴기 루틴이에요.',
        stretches: [
          ('등 말기 이완', '양손을 앞으로 뻗고 등을 둥글게 말아 등 뒤를 늘려주세요.', '30초'),
          ('가슴 펴기', '깍지 낀 손을 등 뒤로 보내고 가슴을 천천히 열어주세요.', '30초'),
          ('엉덩이 스트레칭', '한쪽 발목을 반대쪽 무릎 위에 올려 엉덩이를 늘려주세요.', '양쪽 30초'),
        ],
      ),
      _ => const _Recommendation(
        title: 'BPS-N 추천 스트레칭',
        message: '🐧 바른자세 펭귄과 🦦 중심 수달을 위한\n좋은 흐름 유지 루틴이에요.',
        stretches: [
          ('목 옆 늘리기', '고개를 옆으로 천천히 기울여 목 옆을 부드럽게 늘려주세요.', '양쪽 20초'),
          ('어깨 돌리기', '어깨를 뒤로 크게 천천히 돌려 긴장을 풀어주세요.', '30초'),
          ('전신 기지개', '양팔을 위로 뻗고 몸통을 길게 늘려주세요.', '30초'),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(recommendation.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffF5F1FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              recommendation.message,
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...recommendation.stretches.asMap().entries.map((entry) {
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

class _Recommendation {
  final String title;
  final String message;
  final List<(String, String, String)> stretches;

  const _Recommendation({
    required this.title,
    required this.message,
    required this.stretches,
  });
}
