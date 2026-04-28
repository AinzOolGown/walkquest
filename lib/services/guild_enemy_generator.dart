import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuildEnemyGenerator {
  static final List<String> names = [
    "The Colossus",
    "The Titan",
    "The Horde",
    "The Swarm",
    "The Devourer",
    "The Beast",
  ];

  static final List<String> images = List.generate(
    48,
    (index) => 'assets/enemies/Icon${index + 1}.png',
  );

  static Map<String, String> generate() {
    final random = Random();

    final name = names[random.nextInt(names.length)];
    final image = images[random.nextInt(images.length)];

    return {
      "name": name,
      "image": image,
    };
  }
}

Future<void> generateGuildEnemy(String guildId) async {
  final guildRef =
      FirebaseFirestore.instance.collection('guilds').doc(guildId);

  final guildDoc = await guildRef.get();
  final guildData = guildDoc.data();

  if (guildData == null) return;

  final members = List<String>.from(guildData['members'] ?? []);

  int combinedDailyGoal = 0;

  for (final memberId in members) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .get();

    final userData = userDoc.data();

    combinedDailyGoal +=
        ((userData?['dailyStepGoal'] ?? 8000) as num).toInt();
  }

  final requiredSteps =
      (combinedDailyGoal * 7 * 1.05).round();

  final enemy = GuildEnemyGenerator.generate();

  await guildRef.update({
    'activeGuildEnemy': {
      'name': enemy['name'],
      'image': enemy['image'],
      'requiredSteps': requiredSteps,
      'currentSteps': 0,
      'weekStart': FieldValue.serverTimestamp(),
      'defeated': false,
    }
  });
}