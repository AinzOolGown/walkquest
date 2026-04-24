class Guild {
  final String id;
  final String name;
  final String activityLevel;
  final bool isPrivate;
  final List<dynamic> members;
  final int totalSteps;

  Guild({
    required this.id,
    required this.name,
    required this.activityLevel,
    required this.isPrivate,
    required this.members,
    required this.totalSteps,
  });

  factory Guild.fromDoc(doc) {
    final data = doc.data();
    return Guild(
      id: doc.id,
      name: data['name'] ?? '',
      activityLevel: data['activityLevel'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      members: data['members'] ?? [],
      totalSteps: data['totalSteps'] ?? 0,
    );
  }
}