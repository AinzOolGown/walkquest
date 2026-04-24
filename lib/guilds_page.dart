import 'package:flutter/material.dart';

class GuildsPage extends StatefulWidget {
  const GuildsPage({super.key});

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                      onTap: () {
                        // Future: open guild detail page
                      },
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
}