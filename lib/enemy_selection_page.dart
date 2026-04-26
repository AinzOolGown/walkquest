import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnemySelectionPage extends StatefulWidget {
  const EnemySelectionPage({super.key});

  @override
  State<EnemySelectionPage> createState() => _EnemySelectionPageState();
}

class _EnemySelectionPageState extends State<EnemySelectionPage> {
  String selectedDifficulty = 'Normal';
  bool loading = false;

  Future<void> _confirmSelection() async {
    final user = FirebaseAuth.instance.currentUser!;

    setState(() => loading = true);

    try {
      double multiplier;

      switch (selectedDifficulty) {
        case 'Easy':
          multiplier = 0.9;
          break;
        case 'Hard':
          multiplier = 1.15;
          break;
        default:
          multiplier = 1.0;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data()!;
      final dailyGoal = userData['dailyStepGoal'] ?? 8000;

      final weeklyBaseHp = ((dailyGoal * 7) / 1000).round();
      final enemyHp = (weeklyBaseHp * multiplier).round();

      final enemyName = _generateEnemyName(selectedDifficulty);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hasActiveEnemy': true,
        'selectedDifficulty': selectedDifficulty,
        'currentDifficultyMultiplier': multiplier,
        'activeEnemy': {
          'name': enemyName,
          'tier': selectedDifficulty,
          'maxHp': enemyHp,
          'currentHp': enemyHp,
          'weekStart': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create enemy: $e')),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String _generateEnemyName(String difficulty) {
    final easy = ['Green Slime', 'Cave Bat', 'Wild Boar'];
    final normal = ['Stone Golem', 'Orc Captain', 'Bandit Lord'];
    final hard = ['Dragon Whelp', 'Titan Guard', 'Demon Knight'];

    switch (difficulty) {
      case 'Easy':
        easy.shuffle();
        return easy.first;
      case 'Hard':
        hard.shuffle();
        return hard.first;
      default:
        normal.shuffle();
        return normal.first;
    }
  }
}
