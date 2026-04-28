import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/guilds_page.dart';
import 'package:firebaseshop/services/guild_enemy_generator.dart';
import 'package:firebaseshop/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';



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
    _checkDailyReset();
  }

  Future<void> _checkDailyReset() async {
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

  Future<void> _useAttack(String attackType) async {
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

    // Prevent reuse
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
    bool defeated = enemy['currentHp'] <= 0;

    attacks[attackType] = true;

    if (defeated) {
      int currentGoal = data['dailyStepGoal'] ?? 8000;
      int enemiesDefeated = data['enemiesDefeated'] ?? 0;
      String difficulty = data['selectedDifficulty'] ?? 'Normal';

      double multiplier;

      switch (difficulty) {
        case 'Easy':
          multiplier = 0;
          break;
        case 'Hard':
          multiplier = 100;
          break;
        default:
          multiplier = 250;
      }

      final newGoal = (currentGoal + multiplier).round();

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
        }
      });

      return;
    }else{
      await userRef.update({
        'activeEnemy': enemy,
        'dailyAttacks': attacks,
      });
    }
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

                // Enemy Name
                Text(
                  enemy['name'] ?? 'Unknown Enemy',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Enemy Portrait
                Image.asset(
                  enemy['image'],
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.none,
                ),

                const SizedBox(height: 20),

                // HP Display
                Text(
                  'HP: ${enemy['currentHp']} / ${enemy['maxHp']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: LinearProgressIndicator(
                    value: (enemy['currentHp'] / enemy['maxHp']),
                    minHeight: 12,
                  ),
                ),

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
                    _attackButton(
                      label: "Punch",
                      requiredSteps: punchGoal,
                      currentSteps: _steps,
                      used: attacks['punch'] == true,
                      color: Colors.green,
                      onPressed: () => _useAttack('punch'),
                    ),

                    _attackButton(
                      label: "Slash",
                      requiredSteps: slashGoal,
                      currentSteps: _steps,
                      used: attacks['slash'] == true,
                      color: Colors.blue,
                      onPressed: () => _useAttack('slash'),
                    ),

                    _attackButton(
                      label: "Fireball",
                      requiredSteps: fireballGoal,
                      currentSteps: _steps,
                      used: attacks['fireball'] == true,
                      color: Colors.red,
                      onPressed: () => _useAttack('fireball'),
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

Widget _attackButton({
  required String label,
  required int requiredSteps,
  required int currentSteps,
  required bool used,
  required Color color,
  required VoidCallback onPressed,
}) {
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