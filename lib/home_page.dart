import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/guilds_page.dart';
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

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
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

                // 🏷 Enemy Name
                Text(
                  enemy['name'] ?? 'Unknown Enemy',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // 👾 Enemy Portrait
                Image.asset(
                  enemy['image'],
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.none,
                ),

                const SizedBox(height: 20),

                // ❤️ HP Display
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

                // 👣 Step Count
                Text(
                  'Total Steps: $_steps',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}