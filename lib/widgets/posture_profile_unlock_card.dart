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
                      'START를 누르고 5초 동안 편하게 앉아\n기준 자세를 측정해보세요.',
                      style: TextStyle(height: 1.4, color: Colors.black54),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '5초 기준 자세 측정하기 →',
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
