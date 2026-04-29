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

  IconData get _icon {
    switch (label.toLowerCase()) {
      case 'punch':
        return Icons.sports_mma_rounded;
      case 'slash':
        return Icons.flash_on_rounded;
      case 'fireball':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  String get _statusText {
    if (used) return "Used";
    if (currentSteps >= requiredSteps) return "Ready";
    return "${requiredSteps - currentSteps} left";
  }

  @override
  Widget build(BuildContext context) {
    final charged = currentSteps >= requiredSteps;
    final enabled = charged && !used;

    final backgroundColor = used
        ? Colors.grey.shade200
        : enabled
            ? color
            : Colors.grey.shade100;

    final foregroundColor = used
        ? Colors.grey.shade600
        : enabled
            ? Colors.white
            : Colors.grey.shade700;

    final borderColor = used
        ? Colors.grey.shade300
        : enabled
            ? color
            : Colors.grey.shade300;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      used ? Icons.check_circle_rounded : _icon,
                      color: foregroundColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$currentSteps / $requiredSteps",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: enabled
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? Colors.white.withOpacity(0.18)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: enabled ? Colors.white : Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}