import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/guild_detail_page.dart';
import 'package:firebaseshop/models/guild.dart';
import 'package:firebaseshop/services/guild_enemy_generator.dart';
import 'package:flutter/material.dart';

class GuildsPage extends StatefulWidget {
  const GuildsPage({super.key});

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  String searchQuery = '';

  void _showCreateGuildDialog() {
    final nameController = TextEditingController();
    String activityLevel = "Casual";
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Guild"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Guild Name"),
                  ),

                  DropdownButton<String>(
                    value: activityLevel,
                    items: ["Casual", "Moderate", "Hardcore"]
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => activityLevel = value!);
                    },
                  ),

                  SwitchListTile(
                    title: const Text("Private Guild"),
                    value: isPrivate,
                    onChanged: (value) {
                      setState(() => isPrivate = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser!;

                final guildRef = await FirebaseFirestore.instance
                    .collection('guilds')
                    .add({
                  "name": nameController.text.trim(),
                  "activityLevel": activityLevel,
                  "isPrivate": isPrivate,
                  "ownerId": user.uid,
                  "members": [user.uid],
                  "totalSteps": 0,
                  "createdAt": FieldValue.serverTimestamp(),
                  "guildEnemiesDefeated": 0,
                  "activeGuildEnemy": null,
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  "guildId": guildRef.id,
                });

                await generateGuildEnemy(guildRef.id);

                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinGuild(Guild guild) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final guildRef =
        FirebaseFirestore.instance.collection('guilds').doc(guild.id);

    try {
      // Prevent joining private guilds
      if (guild.isPrivate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This guild is private."),
          ),
        );
        return;
      }

      // Prevent joining if already in a guild
      final userDoc = await userRef.get();
      final userData = userDoc.data();

      final currentGuildId = userData?['guildId'];

      if (currentGuildId != null &&
          currentGuildId.toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Leave your current guild first.",
            ),
          ),
        );
        return;
      }

      // Add user to guild
      await guildRef.update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // Update user guild
      await userRef.update({
        'guildId': guild.id,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Joined ${guild.name}!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to join guild: $e",
          ),
        ),
      );
    }
  }

  Widget _buildGuildList() {
    return Scaffold(
      appBar: AppBar(title: const Text("Guilds")),

      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search guilds...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),

          // 📜 Guild list
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('guilds')
                  .orderBy('totalSteps', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final guilds = snapshot.data!.docs
                    .map((doc) => Guild.fromDoc(doc))
                    .where((guild) =>
                        guild.name.toLowerCase().contains(searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: guilds.length,
                  itemBuilder: (context, index) {
                    final guild = guilds[index];

                    return ListTile(
                      title: Text(guild.name),
                      subtitle: Text(
                          "${guild.activityLevel} • ${guild.members.length} members"),
                      trailing: Text("${guild.totalSteps} steps"),
                      onTap: () => _joinGuild(guild),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ Create guild button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGuildDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!;
        final data = userData.data() as Map<String, dynamic>;
        final guildId = data['guildId'];

        // AUTO SWITCH
        if (guildId != null && guildId.toString().isNotEmpty) {
          return GuildDetailPage(guildId: guildId);
        }

        // fallback to existing UI
        return _buildGuildList();
      },
    );
  }
}