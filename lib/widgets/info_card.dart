import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {

  final String title;
  final String value;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 22,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0,4),
          )
        ],
      ),
      child: Column(
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height:8),

          Text(
            value,
            style: const TextStyle(
              fontSize:28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF725AC1),
            ),
          ),

        ],
      ),
    );
  }
}