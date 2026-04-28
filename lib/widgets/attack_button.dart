import 'package:flutter/material.dart';

class AttackButton extends StatelessWidget {
  final String label;
  final int requiredSteps;
  final int currentSteps;
  final bool used;
  final Color color;
  final VoidCallback onPressed;

  const AttackButton({
    super.key,
    required this.label,
    required this.requiredSteps,
    required this.currentSteps,
    required this.used,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final charged = currentSteps >= requiredSteps;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: used
            ? Colors.grey
            : charged
                ? color
                : Colors.black26,
      ),
      onPressed: (!charged || used) ? null : onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text('$currentSteps / $requiredSteps'),
        ],
      ),
    );
  }
}