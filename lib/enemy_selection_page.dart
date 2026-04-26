import 'package:firebaseshop/services/enemy_generator.dart';
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
  late List<Map<String, String>> enemyChoices;

  @override
  void initState() {
    super.initState();
    enemyChoices = EnemyGenerator.generateUniqueChoices();
  }

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

      // 🔥 Match difficulty to correct unique enemy
      final selectedEnemy = selectedDifficulty == 'Easy'
          ? enemyChoices[0]
          : selectedDifficulty == 'Normal'
              ? enemyChoices[1]
              : enemyChoices[2];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hasActiveEnemy': true,
        'selectedDifficulty': selectedDifficulty,
        'currentDifficultyMultiplier': multiplier,
        'activeEnemy': {
          'name': selectedEnemy['name'],
          'image': selectedEnemy['image'],
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

  Widget _difficultyCard(
    String difficulty,
    String description,
    Color color,
    Map<String, String> enemy,
  ) {
    final isSelected = selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() => selectedDifficulty = difficulty);
      },
      child: Card(
        color: isSelected ? color.withOpacity(0.3) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                enemy['image']!,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(height: 8),
              Text(
                enemy['name']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(difficulty),
              const SizedBox(height: 6),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Choose Your Weekly Challenge'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select your enemy difficulty. Your choice shapes your weekly step battle.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            _difficultyCard(
              'Easy',
              'Lower pressure, steady progress, easier enemy scaling.',
              Colors.green,
              enemyChoices[0],
            ),

            _difficultyCard(
              'Normal',
              'Balanced progression with subtle weekly scaling.',
              Colors.blue,
              enemyChoices[1],
            ),

            _difficultyCard(
              'Hard',
              'Aggressive weekly growth and stronger enemies.',
              Colors.red,
              enemyChoices[2],
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: loading ? null : _confirmSelection,
              child: Text(
                loading ? 'Generating Enemy...' : 'Begin Hunt',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
