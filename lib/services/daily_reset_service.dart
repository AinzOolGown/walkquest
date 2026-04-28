import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyResetService {
  static Future<void> checkAndReset() async {
    final user = FirebaseAuth.instance.currentUser!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    final data = doc.data();

    if (data == null) return;

    final today =
        DateTime.now().toIso8601String().split('T').first;

    final lastReset = data['lastStepResetDate'] ?? today;

    if (lastReset != today) {
      final yesterdaySteps = data['todaySteps'] ?? 0;
      final totalSteps = data['totalSteps'] ?? 0;

      await userRef.update({
        'totalSteps': totalSteps + yesterdaySteps,
        'todaySteps': 0,
        'lastStepResetDate': today,
        'dailyAttacks': {
          'punch': false,
          'slash': false,
          'fireball': false,
        },
        'guildContributionToday': 0,
      });
    }
  }
}