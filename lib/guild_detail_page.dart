import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GuildDetailPage extends StatelessWidget {
  final String guildId;

  const GuildDetailPage({super.key, required this.guildId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Guild")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('guilds')
            .doc(guildId)
            .snapshots(),
        builder: (context, guildSnapshot) {
          if (!guildSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final guildData = guildSnapshot.data!;
          final members = List<String>.from(guildData['members']);

          return FutureBuilder(
            future: _fetchMembersData(members),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data as List<Map<String, dynamic>>;

              // 🔢 Sort leaderboard
              users.sort((a, b) =>
                  (b['todaySteps'] ?? 0).compareTo(a['todaySteps'] ?? 0));

              final currentIndex =
                  users.indexWhere((u) => u['uid'] == currentUser.uid);

              final top10 = users.take(10).toList();

              // If user not in top 10 → replace last entry
              if (currentIndex >= 10) {
                top10[9] = users[currentIndex];
              }

              return Column(
                children: [
                  const SizedBox(height: 20),

                  // 🏷 Guild name
                  Text(
                    guildData['name'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // 🏆 Leaderboard
                  Expanded(
                    child: ListView.builder(
                      itemCount: top10.length,
                      itemBuilder: (context, index) {
                        final user = top10[index];
                        final isMe = user['uid'] == currentUser.uid;

                        final rank = (currentIndex >= 10 && index == 9)
                            ? currentIndex + 1
                            : index + 1;

                        return ListTile(
                          tileColor:
                              isMe ? Colors.yellow.withOpacity(0.3) : null,
                          leading: Text("#$rank"),
                          title: Text(user['username'] ?? "Unknown"),
                          trailing:
                              Text("${user['todaySteps'] ?? 0} steps"),
                        );
                      },
                    ),
                  ),

                  // 🚪 Leave button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => _confirmLeave(context),
                        child: const Text("Leave Guild"),
                      ),
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }