import 'package:flutter/material.dart';

class EnemyDisplay extends StatelessWidget {
  final Map<String, dynamic> enemy;

  const EnemyDisplay({
    super.key,
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          enemy['name'] ?? 'Unknown Enemy',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Image.asset(
          enemy['image'],
          width: MediaQuery.of(context).size.width * 0.8,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.none,
        ),

        const SizedBox(height: 20),

        Text(
          'HP: ${enemy['currentHp']} / ${enemy['maxHp']}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: LinearProgressIndicator(
            value: (enemy['currentHp'] / enemy['maxHp']),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}