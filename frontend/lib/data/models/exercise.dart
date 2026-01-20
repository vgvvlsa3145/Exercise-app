class Exercise {
  final String title;
  final String subtitle;
  final List<String> goals;
  final List<String> steps;
  final String category;

  Exercise({
    required this.title,
    required this.subtitle,
    required this.goals,
    required this.steps,
    required this.category,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      goals: List<String>.from(json['goals'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      category: json['category'] ?? '',
    );
  }
}
