import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseshop/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _toggleNotifications(bool value) async {
    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'notificationsEnabled': value,
    });

    if (value) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleRepeatingReminder();
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

    @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunter Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text('No user data found.'),
            );
          }

          final notificationsEnabled =
              data['notificationsEnabled'] ?? true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // PLAYER INFO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['username'] ?? 'Unknown Hunter',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${data['email'] ?? 'Unknown'}'),
                      Text('Sex: ${data['sex'] ?? 'Unknown'}'),
                      Text('Height: ${data['heightCm'] ?? 0} cm'),
                      Text('Weight: ${data['weightKg'] ?? 0} kg'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              // STATS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Today Steps: ${data['todaySteps'] ?? 0}'),
                      Text('Total Steps: ${data['totalSteps'] ?? 0}'),
                      Text('Daily Goal: ${data['dailyStepGoal'] ?? 0}'),
                      Text(
                        'Enemies Defeated: ${data['enemiesDefeated'] ?? 0}',
                      ),
                      Text(
                        'Current Difficulty: ${data['selectedDifficulty'] ?? 'None'}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SETTINGS
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text(
                        'Daily reminders for step goals',
                      ),
                      value: notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // LOGOUT
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}

