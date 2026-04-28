import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        }
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

    final todaySteps = event.steps;

    await userRef.update({
      'todaySteps': todaySteps,
    });

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
          final easyGoal = (dailyGoal * 0.8).round();
          final normalGoal = dailyGoal;
          final hardGoal = (dailyGoal * 1.25).round();

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
                
                LinearProgressIndicator(
                  value: (_steps / hardGoal).clamp(0.0, 1.0),
                  minHeight: 20,
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Easy\n$easyGoal"),
                    Text("Normal\n$normalGoal"),
                    Text("Hard\n$hardGoal"),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}