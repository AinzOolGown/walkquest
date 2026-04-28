import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/guilds_page.dart';
import 'package:firebaseshop/services/guild_enemy_generator.dart';
import 'package:firebaseshop/settings_page.dart';
import 'package:firebaseshop/widgets/attack_button.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebaseshop/widgets/enemy_display.dart';
import 'package:firebaseshop/services/daily_reset_service.dart';
import 'package:firebaseshop/services/combat_service.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _steps = 0;
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    initStepCounter();
    DailyResetService.checkAndReset();
  }

  Future<void> initStepCounter() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;

      _stepCountStream.listen(
        onStepCount,
        onError: onStepError,
        cancelOnError: true,
      );
    } else {
      print("Permission denied");
    }
  }

  Future<void> onStepCount(StepCount event) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Get current user data
    final doc = await userRef.get();
    final data = doc.data();

    if (data == null) return;

    final todaySteps = event.steps;

    await userRef.update({
      'todaySteps': todaySteps,
    });

    final guildId = data['guildId'];

    // Guild contribution section
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

      // Check guild enemy defeat
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

    setState(() {
      _steps = todaySteps;
    });
  }

  void onStepError(error) {
    print("Step Count Error: $error");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkQuest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData =
              snapshot.data!.data() as Map<String, dynamic>?;
          final dailyGoal = userData?['dailyStepGoal'];
          final punchGoal = (dailyGoal * 0.8).round();
          final slashGoal = dailyGoal;
          final fireballGoal = (dailyGoal * 1.25).round();

          final attacks =
              Map<String, dynamic>.from(userData?['dailyAttacks'] ?? {});

          if (userData == null || userData['activeEnemy'] == null) {
            return Center(
              child: Text(
                'Total Steps: $_steps',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final enemy = userData['activeEnemy'];

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                EnemyDisplay(enemy: enemy),

                const SizedBox(height: 20),

                // Step Count
                Text(
                  'Total Steps: $_steps',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AttackButton(
                      label: "Punch",
                      requiredSteps: punchGoal,
                      currentSteps: _steps,
                      used: attacks['punch'] == true,
                      color: Colors.green,
                      onPressed: () => CombatService.useAttack('punch'),
                    ),

                    AttackButton(
                      label: "Slash",
                      requiredSteps: slashGoal,
                      currentSteps: _steps,
                      used: attacks['slash'] == true,
                      color: Colors.blue,
                      onPressed: () => CombatService.useAttack('slash'),
                    ),

                    AttackButton(
                      label: "Fireball",
                      requiredSteps: fireballGoal,
                      currentSteps: _steps,
                      used: attacks['fireball'] == true,
                      color: Colors.red,
                      onPressed: () => CombatService.useAttack('fireball'),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GuildsPage(),
              ),
            );
          },
          child: const Text("Guild"),
        ),
      ),
    );
  }
}