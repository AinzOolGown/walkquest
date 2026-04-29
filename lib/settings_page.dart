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
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color adventureBlue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFC62828);

  Future<void> _toggleNotifications(bool value) async {
    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'notificationsEnabled': value,
    });

    if (value) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleRepeatingReminder();
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return 0;
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final username = data['username']?.toString() ?? 'Unknown Hunter';
    final email = data['email']?.toString() ?? 'Unknown email';

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
            radius: 34,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    data['selectedDifficulty']?.toString() ?? 'No active difficulty',
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statGrid(Map<String, dynamic> data) {
    final todaySteps = _asInt(data['todaySteps']);
    final totalSteps = _asInt(data['totalSteps']);
    final dailyGoal = _asInt(data['dailyStepGoal']);
    final defeated = _asInt(data['enemiesDefeated']);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _statTile(
          label: "Today",
          value: "$todaySteps",
          icon: Icons.directions_walk_rounded,
          color: primaryGreen,
        ),
        _statTile(
          label: "Total",
          value: "$totalSteps",
          icon: Icons.timeline_rounded,
          color: adventureBlue,
        ),
        _statTile(
          label: "Goal",
          value: "$dailyGoal",
          icon: Icons.flag_rounded,
          color: gold,
        ),
        _statTile(
          label: "Defeated",
          value: "$defeated",
          icon: Icons.shield_moon_rounded,
          color: dangerRed,
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(
            icon,
            color: adventureBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunter Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text('No user data found.'),
            );
          }

          final notificationsEnabled = data['notificationsEnabled'] ?? true;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildProfileHeader(data),
              _sectionCard(
                title: "Adventure Stats",
                icon: Icons.query_stats_rounded,
                color: primaryGreen,
                children: [
                  _statGrid(data),
                ],
              ),
              _sectionCard(
                title: "Player Info",
                icon: Icons.badge_rounded,
                color: adventureBlue,
                children: [
                  _infoRow(
                    icon: Icons.wc_rounded,
                    label: "Sex",
                    value: data['sex']?.toString() ?? 'Unknown',
                  ),
                  _infoRow(
                    icon: Icons.height_rounded,
                    label: "Height",
                    value: "${data['heightCm'] ?? 0} cm",
                  ),
                  _infoRow(
                    icon: Icons.monitor_weight_rounded,
                    label: "Weight",
                    value: "${data['weightKg'] ?? 0} kg",
                  ),
                  _infoRow(
                    icon: Icons.sports_martial_arts_rounded,
                    label: "Current Difficulty",
                    value: data['selectedDifficulty']?.toString() ?? 'None',
                  ),
                ],
              ),
              _sectionCard(
                title: "Settings",
                icon: Icons.settings_rounded,
                color: gold,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryGreen,
                    title: const Text(
                      'Enable Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: const Text(
                      'Daily reminders for step goals',
                    ),
                    value: notificationsEnabled == true,
                    onChanged: _toggleNotifications,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}