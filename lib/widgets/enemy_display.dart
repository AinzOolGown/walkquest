import 'package:flutter/material.dart';

class EnemyDisplay extends StatelessWidget {
  final Map enemy;

  const EnemyDisplay({
    super.key,
    required this.enemy,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = enemy['image']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFE8F5E9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: imagePath == null || imagePath.isEmpty
                ? const Icon(
                    Icons.shield_moon_rounded,
                    size: 92,
                    color: Color(0xFFC62828),
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.shield_moon_rounded,
                        size: 92,
                        color: Color(0xFFC62828),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              enemy['tier']?.toString() ?? "Active Enemy",
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}