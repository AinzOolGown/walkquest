import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseshop/guilds_page.dart';
import 'package:firebaseshop/settings_page.dart';
import 'package:firebaseshop/widgets/attack_button.dart';
import 'package:flutter/material.dart';
import 'package:firebaseshop/widgets/enemy_display.dart';
import 'package:firebaseshop/services/daily_reset_service.dart';
import 'package:firebaseshop/services/combat_service.dart';
import 'package:firebaseshop/services/step_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _steps = 0;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color adventureBlue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();

    StepService.startTracking(
      onStepsUpdated: (steps) {
        if (mounted) {
          setState(() {
            _steps = steps;
          });
        }
      },
    );

    DailyResetService.checkAndReset();
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return fallback;
  }

  double _progressValue(int current, int goal) {
    if (goal <= 0) return 0;
    final value = current / goal;
    return value.clamp(0.0, 1.0);
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily Adventure",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Turn your steps into attacks.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 12),
              Text(
                "$_steps",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "steps",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int dailyGoal,
    required int punchGoal,
    required int slashGoal,
    required int fireballGoal,
  }) {
    final progress = _progressValue(_steps, dailyGoal);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_rounded, color: primaryGreen),
                SizedBox(width: 8),
                Text(
                  "Daily Step Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: const Color(0xFFE2E8DD),
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$_steps / $dailyGoal steps completed",
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStepChip("Punch", punchGoal, Icons.sports_mma, primaryGreen),
                _buildStepChip("Slash", slashGoal, Icons.flash_on, adventureBlue),
                _buildStepChip("Fireball", fireballGoal, Icons.local_fire_department, dangerRed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(
    String label,
    int requiredSteps,
    IconData icon,
    Color color,
  ) {
    final ready = _steps >= requiredSteps;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: ready ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ready ? color.withOpacity(0.6) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: ready ? color : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $requiredSteps",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ready ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemyCard(Map enemy) {
    final currentHp = _asInt(enemy['currentHp'], 0);
    final maxHp = _asInt(enemy['maxHp'], 1);
    final hpProgress = _progressValue(currentHp, maxHp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    enemy['name']?.toString() ?? "Unknown Enemy",
                    style: const TextStyle(
                      fontSize: 21,
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
                    color: dangerRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    enemy['tier']?.toString() ?? "Enemy",
                    style: const TextStyle(
                      color: dangerRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EnemyDisplay(enemy: enemy),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: dangerRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: hpProgress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFFFCDD2),
                      color: dangerRed,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "$currentHp / $maxHp HP",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackPanel({
    required int punchGoal,
    required int slashGoal,
    required int fireballGoal,
    required Map<String, dynamic> attacks,
  }) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: gold),
                SizedBox(width: 8),
                Text(
                  "Available Attacks",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AttackButton(
                  label: "Punch",
                  requiredSteps: punchGoal,
                  currentSteps: _steps,
                  used: attacks['punch'] == true,
                  color: primaryGreen,
                  onPressed: () => CombatService.useAttack('punch'),
                ),
                AttackButton(
                  label: "Slash",
                  requiredSteps: slashGoal,
                  currentSteps: _steps,
                  used: attacks['slash'] == true,
                  color: adventureBlue,
                  onPressed: () => CombatService.useAttack('slash'),
                ),
                AttackButton(
                  label: "Fireball",
                  requiredSteps: fireballGoal,
                  currentSteps: _steps,
                  used: attacks['fireball'] == true,
                  color: dangerRed,
                  onPressed: () => CombatService.useAttack('fireball'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEnemyState() {
    return ListView(
      children: [
        _buildHeroHeader(),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(
                  Icons.explore_rounded,
                  size: 60,
                  color: adventureBlue.withOpacity(0.85),
                ),
                const SizedBox(height: 14),
                const Text(
                  "No active enemy yet",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose a weekly challenge to begin your WalkQuest battle.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Current steps: $_steps",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkQuest'),
        actions: [
          IconButton(
            tooltip: "Profile & Settings",
            icon: const Icon(Icons.person_rounded),
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
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          final dailyGoal = _asInt(userData?['dailyStepGoal'], 8000);
          final punchGoal = (dailyGoal * 0.8).round();
          final slashGoal = dailyGoal;
          final fireballGoal = (dailyGoal * 1.25).round();
          final attacks = Map<String, dynamic>.from(
            userData?['dailyAttacks'] ?? {},
          );

          if (userData == null || userData['activeEnemy'] == null) {
            return _buildNoEnemyState();
          }

          final enemy = Map<String, dynamic>.from(userData['activeEnemy']);

          return ListView(
            children: [
              _buildHeroHeader(),
              _buildProgressCard(
                dailyGoal: dailyGoal,
                punchGoal: punchGoal,
                slashGoal: slashGoal,
                fireballGoal: fireballGoal,
              ),
              _buildEnemyCard(enemy),
              _buildAttackPanel(
                punchGoal: punchGoal,
                slashGoal: slashGoal,
                fireballGoal: fireballGoal,
                attacks: attacks,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.groups_rounded),
            label: const Text("Open Guilds"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GuildsPage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}