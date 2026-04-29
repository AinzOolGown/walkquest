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

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color adventureBlue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFC62828);

  void _showCreateGuildDialog() {
    final nameController = TextEditingController();
    String activityLevel = "Casual";
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Create Guild",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Guild Name",
                      prefixIcon: Icon(Icons.groups_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: activityLevel,
                    decoration: const InputDecoration(
                      labelText: "Activity Level",
                      prefixIcon: Icon(Icons.local_fire_department_rounded),
                    ),
                    items: ["Casual", "Moderate", "Hardcore"]
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => activityLevel = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Private Guild",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text("Only invited players can join"),
                    value: isPrivate,
                    activeColor: primaryGreen,
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
                final guildName = nameController.text.trim();

                if (guildName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a guild name."),
                    ),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser!;

                final guildRef =
                    await FirebaseFirestore.instance.collection('guilds').add({
                  "name": guildName,
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

                if (!mounted) return;
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final guildRef = FirebaseFirestore.instance.collection('guilds').doc(guild.id);

    try {
      if (guild.isPrivate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This guild is private."),
          ),
        );
        return;
      }

      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final currentGuildId = userData?['guildId'];

      if (currentGuildId != null && currentGuildId.toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Leave your current guild first."),
          ),
        );
        return;
      }

      await guildRef.update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      await userRef.update({
        'guildId': guild.id,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Joined ${guild.name}!"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to join guild: $e"),
        ),
      );
    }
  }

  Color _activityColor(String level) {
    switch (level.toLowerCase()) {
      case 'hardcore':
        return dangerRed;
      case 'moderate':
        return gold;
      default:
        return primaryGreen;
    }
  }

  IconData _activityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'hardcore':
        return Icons.local_fire_department_rounded;
      case 'moderate':
        return Icons.bolt_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(20),
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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Join a Guild",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Team up, compare steps, and defeat guild enemies together.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search guilds...",
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (value) {
          setState(() => searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildGuildCard(Guild guild, int rank) {
    final activityColor = _activityColor(guild.activityLevel);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _joinGuild(guild),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: adventureBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "#$rank",
                    style: const TextStyle(
                      color: adventureBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guild.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(
                          icon: _activityIcon(guild.activityLevel),
                          label: guild.activityLevel,
                          color: activityColor,
                        ),
                        _infoChip(
                          icon: Icons.people_rounded,
                          label: "${guild.members.length} members",
                          color: adventureBlue,
                        ),
                        if (guild.isPrivate)
                          _infoChip(
                            icon: Icons.lock_rounded,
                            label: "Private",
                            color: dangerRed,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${guild.totalSteps} total steps",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                guild.isPrivate
                    ? Icons.lock_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: guild.isPrivate ? dangerRed : Colors.black38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_2_rounded,
              size: 72,
              color: adventureBlue.withOpacity(0.75),
            ),
            const SizedBox(height: 14),
            const Text(
              "No guilds found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create a new guild or try a different search name.",
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

  Widget _buildGuildList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guilds"),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('guilds')
                  .orderBy('totalSteps', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final guilds = snapshot.data!.docs
                    .map((doc) => Guild.fromDoc(doc))
                    .where(
                      (guild) =>
                          guild.name.toLowerCase().contains(searchQuery),
                    )
                    .toList();

                if (guilds.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: guilds.length,
                  itemBuilder: (context, index) {
                    final guild = guilds[index];
                    return _buildGuildCard(guild, index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateGuildDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Create Guild",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = snapshot.data!;
        final data = userData.data() as Map<String, dynamic>;
        final guildId = data['guildId'];

        if (guildId != null && guildId.toString().isNotEmpty) {
          return GuildDetailPage(guildId: guildId);
        }

        return _buildGuildList();
      },
    );
  }
}