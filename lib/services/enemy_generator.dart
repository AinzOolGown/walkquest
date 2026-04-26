import 'dart:math';

class EnemyGenerator {
  static final List<String> names = [
    "The Beast",
    "The Monster",
    "The Enemy",
    "The Horror",
    "The Fiend",
    "The Brute",
    "The Terror",
    "The Stalker",
    "The Ravager",
    "The Nightmare",
  ];

  static final List<String> images = List.generate(
    48,
    (index) => 'assets/enemies/Icon${index + 1}.png',
  );

  static List<Map<String, String>> generateUniqueChoices() {
    final random = Random();

    final shuffledNames = [...names]..shuffle(random);
    final shuffledImages = [...images]..shuffle(random);

    return List.generate(3, (index) {
      return {
        "name": shuffledNames[index],
        "image": shuffledImages[index],
      };
    });
  }
}