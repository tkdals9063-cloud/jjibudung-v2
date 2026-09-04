import 'package:flutter/material.dart';

import '../core/app_tab_controller.dart';

class PostureProfileSummaryCard extends StatelessWidget {
  final String profileId;

  const PostureProfileSummaryCard({
    super.key,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    final profile = switch (profileId) {
      'forward' => _ProfileVisual(
          code: 'FLS-A',
          firstEmoji: '🐢',
          secondEmoji: '🦊',
          name: '거북목 탐험가 + 앞기울임 여우',
          subtitle: '추천 스트레칭 보기 →',
        ),
      'slouch' => _ProfileVisual(
          code: 'SSS-P',
          firstEmoji: '🐻',
          secondEmoji: '🦔',
          name: '꾸벅 곰 + 말린 고슴도치',
          subtitle: '자세 리셋 스트레칭 보기 →',
        ),
      _ => _ProfileVisual(
          code: 'BPS-N',
          firstEmoji: '🐧',
          secondEmoji: '🦦',
          name: '바른자세 탐험가 + 중심 펭귄',
          subtitle: '내 자세 친구들 보기 →',
          imagePath: 'assets/characters/profile_balanced_penguin.png',
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: AppTabController.openStretchTab,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffF5F1FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              if (profile.imagePath != null)
                SizedBox(
                  width: 104,
                  height: 74,
                  child: Image.asset(profile.imagePath!, fit: BoxFit.contain),
                )
              else ...[
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(profile.firstEmoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                const Text('+', style: TextStyle(fontSize: 22, color: Color(0xff725AC1))),
                const SizedBox(width: 12),
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(profile.secondEmoji, style: const TextStyle(fontSize: 32)),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.code,
                      style: const TextStyle(
                        color: Color(0xff725AC1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      profile.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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

class _ProfileVisual {
  final String code;
  final String firstEmoji;
  final String secondEmoji;
  final String name;
  final String subtitle;
  final String? imagePath;

  const _ProfileVisual({
    required this.code,
    required this.firstEmoji,
    required this.secondEmoji,
    required this.name,
    required this.subtitle,
    this.imagePath,
  });
}
