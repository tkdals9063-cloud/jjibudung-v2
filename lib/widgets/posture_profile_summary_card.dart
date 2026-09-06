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
      'forward' => const _ProfileVisual(
          code: 'FLS-A',
          name: '거북목 탐험가 + 앞기울임 여우',
          subtitle: '추천 스트레칭 보기 →',
          imagePath: 'assets/characters/avatar_forward_fox.png',
        ),
      'slouch' => const _ProfileVisual(
          code: 'SSS-P',
          name: '쉬었음 탐험가 + 뒤말림 고슴도치',
          subtitle: '자세 리셋 스트레칭 보기 →',
          imagePath: 'assets/characters/avatar_rested_hedgehog.png',
        ),
      'tilted' => const _ProfileVisual(
          code: 'ATS-P',
          name: '삐딱 탐험가 + 기우뚱 팬더',
          subtitle: '균형 리셋 스트레칭 보기 →',
          imagePath: 'assets/characters/avatar_tilted_panda.png',
        ),
      _ => const _ProfileVisual(
          code: 'BPS-N',
          name: '바른자세 탐험가 + 중심 펭귄',
          subtitle: '내 자세 친구들 보기 →',
          imagePath: 'assets/characters/avatar_balanced_penguin.png',
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
              SizedBox(
                width: 108,
                height: 98,
                child: Image.asset(profile.imagePath, fit: BoxFit.contain),
              ),
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
                    const SizedBox(height: 4),
                    Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
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
  final String name;
  final String subtitle;
  final String imagePath;

  const _ProfileVisual({
    required this.code,
    required this.name,
    required this.subtitle,
    required this.imagePath,
  });
}
