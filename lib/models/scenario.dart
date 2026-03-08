/// Summary of a training scenario for listing.
class ScenarioSummary {
  final String scenarioId;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String personaEmotion;
  final String personaPersonality;
  final int estimatedDuration;
  final List<String> tags;

  ScenarioSummary({
    required this.scenarioId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.personaEmotion,
    required this.personaPersonality,
    required this.estimatedDuration,
    required this.tags,
  });

  factory ScenarioSummary.fromJson(Map<String, dynamic> json) {
    return ScenarioSummary(
      scenarioId: json['scenario_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      personaEmotion: json['persona_emotion'] ?? '',
      personaPersonality: json['persona_personality'] ?? '',
      estimatedDuration: json['estimated_duration'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
