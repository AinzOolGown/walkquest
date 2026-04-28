import 'dart:math';

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