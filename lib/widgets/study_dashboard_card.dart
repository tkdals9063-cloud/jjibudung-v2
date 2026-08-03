import 'package:flutter/material.dart';

class StudyDashboardCard extends StatelessWidget {
  final int goodPostureTime;
  final int totalMeasureTime;
  final List<bool> weekUsage;
  final VoidCallback onPressed;

  const StudyDashboardCard({
    super.key,
    required this.goodPostureTime,
    required this.totalMeasureTime,
    required this.weekUsage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalMeasureTime == 0
        ? 0.0
        : (goodPostureTime / totalMeasureTime).clamp(0.0, 1.0);
    final usedDays = weekUsage.where((used) => used).length;
    final todayIndex = DateTime.now().weekday - 1;
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff1B2130),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            '바른자세 유지시간',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            Duration(seconds: goodPostureTime).toString().split('.').first,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '전체 측정시간',
                      style: TextStyle(color: Colors.white54),
                    ),
                    Text(
                      Duration(
                        seconds: totalMeasureTime,
                      ).toString().split('.').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('START', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 이번 주 사용',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$usedDays / 7일',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (index) {
              return _day(
                label: labels[index],
                active: weekUsage[index],
                isToday: index == todayIndex,
              );
            }),
          ),
        ],
      ),
    );
  }
}

Widget _day({
  required String label,
  required bool active,
  required bool isToday,
}) {
  return Column(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? const Color(0xff725AC1) : Colors.white24,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: active
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: TextStyle(
          color: isToday ? Colors.white : Colors.white60,
          fontSize: 12,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}
