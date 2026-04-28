import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CombatService {
  static Future<void> useAttack(String attackType) async {
    final user = FirebaseAuth.instance.currentUser!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    final data = doc.data();

    if (data == null || data['activeEnemy'] == null) return;

    final enemy =
        Map<String, dynamic>.from(data['activeEnemy']);

    final attacks =
        Map<String, dynamic>.from(data['dailyAttacks']);

    if (attacks[attackType] == true) return;

    final maxHp = enemy['maxHp'];

    int damage;

    switch (attackType) {
      case 'punch':
        damage = (maxHp * 0.08).round();
        break;
      case 'fireball':
        damage = (maxHp * 0.22).round();
        break;
      default:
        damage = (maxHp * 0.15).round();
    }

    enemy['currentHp'] =
        (enemy['currentHp'] - damage).clamp(0, maxHp);

    final defeated = enemy['currentHp'] <= 0;

    attacks[attackType] = true;

    if (defeated) {
      int currentGoal = data['dailyStepGoal'] ?? 8000;
      int enemiesDefeated = data['enemiesDefeated'] ?? 0;
      String difficulty =
          data['selectedDifficulty'] ?? 'Normal';

      int increase;

      switch (difficulty) {
        case 'Easy':
          increase = 0;
          break;
        case 'Hard':
          increase = 100;
          break;
        default:
          increase = 250;
      }

      final newGoal = currentGoal + increase;

      await userRef.update({
        'dailyStepGoal': newGoal,
        'enemiesDefeated': enemiesDefeated + 1,
        'hasActiveEnemy': false,
        'selectedDifficulty': null,
        'activeEnemy': null,
        'dailyAttacks': {
          'punch': false,
          'slash': false,
          'fireball': false,
        },
      });

      return;
    }

    await userRef.update({
      'activeEnemy': enemy,
      'dailyAttacks': attacks,
    });
  }
}