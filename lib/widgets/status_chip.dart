import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final bool isPaused;
  final bool isBadPosture;

  const StatusChip({
    super.key,
    required this.isPaused,
    required this.isBadPosture,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (isPaused) {
      color = Colors.grey;
      text = "일시정지";
      icon = Icons.pause_circle;
    } else if (isBadPosture) {
      color = Colors.red;
      text = "나쁜 자세";
      icon = Icons.warning_rounded;
    } else {
      color = Colors.green;
      text = "좋은 자세";
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}