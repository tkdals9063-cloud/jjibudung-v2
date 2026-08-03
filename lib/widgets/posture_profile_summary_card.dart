import 'package:flutter/material.dart';

import '../screens/stretch_recommendation_screen.dart';

class PostureProfileSummaryCard extends StatelessWidget {
  const PostureProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StretchRecommendationScreen(),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffF5F1FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text('🐢', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 12),
              const Text(
                '+',
                style: TextStyle(fontSize: 22, color: Color(0xff725AC1)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text('🦊', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLS-A',
                      style: TextStyle(
                        color: Color(0xff725AC1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '거북목 탐험가 + 앞기울임 여우',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '추천 스트레칭 보기 →',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
