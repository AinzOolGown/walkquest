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

  static const Color easyGreen = Color(0xFF2E7D32);
  static const Color normalBlue = Color(0xFF1565C0);
  static const Color hardRed = Color(0xFFC62828);
  static const Color gold = Color(0xFFFFB300);

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

      final selectedEnemy = selectedDifficulty == 'Easy'
          ? enemyChoices[0]
          : selectedDifficulty == 'Normal'
              ? enemyChoices[1]
              : enemyChoices[2];

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
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

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create enemy: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return easyGreen;
      case 'Hard':
        return hardRed;
      default:
        return normalBlue;
    }
  }

  IconData _difficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Icons.eco_rounded;
      case 'Hard':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  String _difficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return "Best for steady progress";
      case 'Hard':
        return "Best for high challenge";
      default:
        return "Best balanced option";
    }
  }

  Widget _difficultyCard(
    String difficulty,
    String description,
    Map<String, String> enemy,
  ) {
    final color = _difficultyColor(difficulty);
    final isSelected = selectedDifficulty == difficulty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withOpacity(0.25)
                : Colors.black.withOpacity(0.08),
            blurRadius: isSelected ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() => selectedDifficulty = difficulty);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    enemy['image']!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enemy['name']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _difficultyIcon(difficulty),
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          difficulty,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _difficultyLabel(difficulty),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.explore_rounded,
            color: Colors.white,
            size: 42,
          ),
          SizedBox(height: 14),
          Text(
            "Choose Your Weekly Challenge",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Pick an enemy difficulty. Your real-world steps become attacks during the week.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkQuest Challenge'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _difficultyCard(
                      'Easy',
                      'Lower pressure, steady progress, easier enemy scaling.',
                      enemyChoices[0],
                    ),
                    _difficultyCard(
                      'Normal',
                      'Balanced progression with fair weekly scaling.',
                      enemyChoices[1],
                    ),
                    _difficultyCard(
                      'Hard',
                      'Aggressive weekly growth and stronger enemies.',
                      enemyChoices[2],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _confirmSelection,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sports_martial_arts_rounded),
                        label: Text(
                          loading ? 'Generating Enemy...' : 'Begin Hunt',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}