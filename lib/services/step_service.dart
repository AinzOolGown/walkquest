import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/services/guild_enemy_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class StepService {
  static Stream<StepCount>? _stepCountStream;

  static Future<void> startTracking({
    required Function(int steps) onStepsUpdated,
  }) async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;

      _stepCountStream!.listen(
        (event) async {
          await _onStepCount(event, onStepsUpdated);
        },
        onError: _onStepError,
        cancelOnError: true,
      );
    } else {
      print("Permission denied");
    }
  }

  static Future<void> _onStepCount(
    StepCount event,
    Function(int steps) onStepsUpdated,
  ) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    final data = doc.data();

    if (data == null) return;

    final todaySteps = event.steps;

    await userRef.update({
      'todaySteps': todaySteps,
    });

    final guildId = data['guildId'];

    if (guildId != null) {
      final guildRef = FirebaseFirestore.instance
          .collection('guilds')
          .doc(guildId);

      final previousContribution =
          data['guildContributionToday'] ?? 0;

      final delta = todaySteps - previousContribution;

      if (delta > 0) {
        await guildRef.update({
          'activeGuildEnemy.currentSteps':
              FieldValue.increment(delta),
        });

        await userRef.update({
          'guildContributionToday': todaySteps,
        });
      }

      final guildDoc = await guildRef.get();
      final guildData = guildDoc.data();

      if (guildData != null &&
          guildData['activeGuildEnemy'] != null) {
        final enemy = guildData['activeGuildEnemy'];

        if (enemy['currentSteps'] >= enemy['requiredSteps']) {
          final defeated =
              (guildData['guildEnemiesDefeated'] ?? 0) + 1;

          await guildRef.update({
            'guildEnemiesDefeated': defeated,
          });

          await generateGuildEnemy(guildId);
        }
      }
    }

    onStepsUpdated(todaySteps);
  }

  static void _onStepError(error) {
    print("Step Count Error: $error");
  }
}