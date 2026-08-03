import 'package:flutter/material.dart';

import 'stretch_recommendation_screen.dart';

class PostureProfileScreen extends StatelessWidget {
  const PostureProfileScreen({super.key});

  void _openStretch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StretchRecommendationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 자세 친구들',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '내 자세 경향을 쉽고 가볍게 알아봐요.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openStretch(context),
                  icon: const Icon(Icons.self_improvement_rounded),
                  label: const Text('추천 스트레칭'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xffF5F1FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff725AC1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FLS-A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      Expanded(
                        child: _FriendProfile(
                          emoji: '🐢',
                          name: '거북목 탐험가',
                          caption: '상체 캐릭터',
                        ),
                      ),
                      Text(
                        '+',
                        style: TextStyle(
                          fontSize: 30,
                          color: Color(0xff725AC1),
                        ),
                      ),
                      Expanded(
                        child: _FriendProfile(
                          emoji: '🦊',
                          name: '앞기울임 여우',
                          caption: '골반 펫',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              icon: Icons.person_outline_rounded,
              title: 'FLS · 앞으로 쏠림 경향',
              description: '오래 앉아 있거나 화면을 볼 때 상체가 앞으로 기울기 쉬워요.',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.airline_seat_recline_extra_outlined,
              title: 'A · 골반 앞기울임 경향',
              description: '허리가 과하게 꺾이지 않도록 배와 엉덩이에 가볍게 힘을 주세요.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff1B2130),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 작은 팁', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                    '턱은 살짝 당기고, 어깨 힘을 빼보세요.\n30분마다 한 번 가볍게 일어나면 더 좋아요.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 46),
            GestureDetector(
              onLongPress: () => _openStretch(context),
              child: Container(
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xff725AC1).withValues(alpha: 0.08),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_double_arrow_down_rounded,
                      color: Color(0xff725AC1),
                    ),
                    SizedBox(height: 8),
                    Opacity(
                      opacity: 0.58,
                      child: Text(
                        '길게 누르면 추천 스트레칭으로 이동해요',
                        style: TextStyle(
                          color: Color(0xff725AC1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendProfile extends StatelessWidget {
  final String emoji;
  final String name;
  final String caption;

  const _FriendProfile({
    required this.emoji,
    required this.name,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(
          caption,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE6DFFE)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff725AC1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(height: 1.45, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
