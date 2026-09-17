import 'package:flutter/material.dart';

class PostureProfileUnlockCard extends StatelessWidget {
  final VoidCallback onPressed;

  const PostureProfileUnlockCard({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffF5F1FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text('✨', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나의 자세 친구를 만나보세요',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'START를 누른 뒤 5초 안에 휴대폰을 주머니에 넣고\n바르게 서서 다음 5초 동안 측정해보세요.',
                      style: TextStyle(height: 1.4, color: Colors.black54),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '준비 5초 + 측정 5초 시작하기 →',
                      style: TextStyle(
                        color: Color(0xff725AC1),
                        fontWeight: FontWeight.w700,
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
