import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildDetailPage extends StatelessWidget {
  final String guildId;

  const GuildDetailPage({
    super.key,
    required this.guildId,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color adventureBlue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFC62828);

  Future<List<Map<String, dynamic>>> _fetchMembersData(
    List<dynamic> memberIds,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final results = await Future.wait(
      memberIds.map((id) async {
        final doc = await firestore.collection('users').doc(id.toString()).get();
        final data = doc.data() ?? {};

        return {
          "uid": id.toString(),
          "username": data['username'] ?? "Unknown Hunter",
          "todaySteps": data['todaySteps'] ?? 0,
        };
      }),
    );

    return results;
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Leave Guild",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "Are you sure you want to leave this guild?",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser!;
                final guildRef = FirebaseFirestore.instance
                    .collection('guilds')
                    .doc(guildId);

                await guildRef.update({
                  "members": FieldValue.arrayRemove([user.uid]),
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  "guildId": null,
                });

                Navigator.pop(context);
              },
              child: const Text("Leave"),
            ),
          ],
        );
      },
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return 0;
  }

  Widget _buildHeader(Map<String, dynamic> guildData, int memberCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guildData['name']?.toString() ?? "Guild",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$memberCount members • ${guildData['activityLevel'] ?? 'Casual'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    "${guildData['totalSteps'] ?? 0} total guild steps",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildEnemyCard(Map<String, dynamic>? guildEnemy) {
    if (guildEnemy == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(
                Icons.shield_moon_rounded,
                size: 56,
                color: dangerRed.withOpacity(0.75),
              ),
              const SizedBox(height: 12),
              const Text(
                "No guild enemy active",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "A guild enemy will appear when the guild challenge is generated.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentSteps = _asInt(guildEnemy['currentSteps']);
    final requiredSteps = _asInt(guildEnemy['requiredSteps']);
    final progress = requiredSteps <= 0
        ? 0.0
        : (currentSteps / requiredSteps).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_moon_rounded,
                  color: dangerRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guildEnemy['name']?.toString() ?? "Guild Enemy",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    "Raid",
                    style: TextStyle(
                      color: dangerRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Image.asset(
                guildEnemy['image'],
                height: 190,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.shield_moon_rounded,
                    size: 90,
                    color: dangerRed,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  color: primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFE2E8DD),
                      color: primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "$currentSteps / $requiredSteps",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(List<Map<String, dynamic>> users, String currentUid) {
    users.sort(
      (a, b) => _asInt(b['todaySteps']).compareTo(_asInt(a['todaySteps'])),
    );

    final currentIndex = users.indexWhere((user) => user['uid'] == currentUid);
    final topUsers = users.take(10).toList();

    if (currentIndex >= 10 && topUsers.isNotEmpty) {
      topUsers[topUsers.length - 1] = users[currentIndex];
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  color: gold,
                ),
                SizedBox(width: 8),
                Text(
                  "Daily Leaderboard",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (topUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "No members to display yet.",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ...List.generate(topUsers.length, (index) {
                final user = topUsers[index];
                final isMe = user['uid'] == currentUid;
                final rank = (currentIndex >= 10 && index == topUsers.length - 1)
                    ? currentIndex + 1
                    : index + 1;

                return _leaderboardTile(
                  rank: rank,
                  username: user['username']?.toString() ?? "Unknown Hunter",
                  steps: _asInt(user['todaySteps']),
                  isMe: isMe,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardTile({
    required int rank,
    required String username,
    required int steps,
    required bool isMe,
  }) {
    Color rankColor;

    if (rank == 1) {
      rankColor = gold;
    } else if (rank == 2) {
      rankColor = Colors.blueGrey;
    } else if (rank == 3) {
      rankColor = Colors.brown;
    } else {
      rankColor = adventureBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? primaryGreen.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? primaryGreen.withOpacity(0.35) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: rankColor.withOpacity(0.14),
            child: Text(
              "#$rank",
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? "$username  (You)" : username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$steps steps",
            style: TextStyle(
              color: isMe ? primaryGreen : Colors.black54,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guild"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guilds')
            .doc(guildId)
            .snapshots(),
        builder: (context, guildSnapshot) {
          if (!guildSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!guildSnapshot.data!.exists) {
            return const Center(
              child: Text("Guild not found."),
            );
          }

          final guildData = guildSnapshot.data!.data() as Map<String, dynamic>;
          final members = List<dynamic>.from(guildData['members'] ?? []);
          final guildEnemy = guildData['activeGuildEnemy'] == null
              ? null
              : Map<String, dynamic>.from(guildData['activeGuildEnemy']);

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchMembersData(members),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data!;

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildHeader(guildData, members.length),
                  _buildGuildEnemyCard(guildEnemy),
                  _buildLeaderboard(users, currentUser.uid),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dangerRed,
                        side: const BorderSide(
                          color: dangerRed,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _confirmLeave(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        "Leave Guild",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}