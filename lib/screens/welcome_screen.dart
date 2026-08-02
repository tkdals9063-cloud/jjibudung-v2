import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/info_card.dart';
import 'preparation_screen.dart';
import '../data/quotes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<QuotesData> quotes = [
  QuotesData(
    quote: "성공은 매일 반복한 작은 노력들의 합이다.",
    author: "로버트 콜리어",
  ),
  QuotesData(
    quote: "우리는 반복하는 행동의 결과물이다.",
    author: "아리스토텔레스",
  ),
  QuotesData(
    quote: "천재는 1%의 영감과 99%의 노력이다.",
    author: "토머스 에디슨",
  ),
  QuotesData(
    quote: "미래를 예측하는 가장 좋은 방법은 미래를 만드는 것이다.",
    author: "피터 드러커",
  ),
  QuotesData(
    quote: "오늘의 작은 성장이 내일의 큰 변화를 만든다.",
    author: "제임스 클리어",
  ),
];

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "좋은 아침입니다 ☀️";
    } else if (hour < 18) {
      return "좋은 오후입니다 🌤";
    } else {
      return "좋은 저녁입니다 🌙";
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = quotes[Random().nextInt(quotes.length)];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Text(
                greeting(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "찌뿌둥",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff725AC1),
                ),
              ),

              const SizedBox(height: 28),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const Text(
                        "오늘의 명언",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
  "\"${quote.quote}\"",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "- ${quote.author}",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const InfoCard(
                title: "⭐ 현재 포인트",
                value: "0 pt",
              ),

              const SizedBox(height: 16),

              const InfoCard(
                title: "🌱 현재 레벨",
                value: "Lv.1 새싹",
              ),

              const SizedBox(height: 16),

              const InfoCard(
                title: "📚 오늘 공부시간",
                value: "00:00:00",
              ),

              const SizedBox(height: 16),

              const InfoCard(
                title: "😊 바른 자세 유지율",
                value: "100%",
              ),

              const SizedBox(height: 16),

              const InfoCard(
                title: "🔥 연속 공부",
                value: "0일",
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    "공부 시작",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PreparationScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: const [

                      Text(
                        "💪 오늘의 스트레칭",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "오래 앉아 있었다면\n목과 어깨를 가볍게 풀어보세요.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}