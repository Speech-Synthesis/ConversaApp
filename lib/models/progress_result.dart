/// Model representing a completed simulation result for progress tracking.
class ProgressResult {
  final String sessionId;
  final String scenarioId;
  final String scenarioName;
  final String difficulty;
  final DateTime completedAt;
  final int overallScore;
  final int empathyScore;
  final int deEscalationScore;
  final int communicationClarityScore;
  final int problemSolvingScore;
  final int efficiencyScore;
  final String grade;
  final double durationSeconds;

  ProgressResult({
    required this.sessionId,
    required this.scenarioId,
    required this.scenarioName,
    required this.difficulty,
    required this.completedAt,
    required this.overallScore,
    required this.empathyScore,
    required this.deEscalationScore,
    required this.communicationClarityScore,
    required this.problemSolvingScore,
    required this.efficiencyScore,
    required this.grade,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'scenario_id': scenarioId,
      'scenario_name': scenarioName,
      'difficulty': difficulty,
      'completed_at': completedAt.toIso8601String(),
      'overall_score': overallScore,
      'empathy_score': empathyScore,
      'de_escalation_score': deEscalationScore,
      'communication_clarity_score': communicationClarityScore,
      'problem_solving_score': problemSolvingScore,
      'efficiency_score': efficiencyScore,
      'grade': grade,
      'duration_seconds': durationSeconds,
    };
  }

  factory ProgressResult.fromJson(Map<String, dynamic> json) {
    return ProgressResult(
      sessionId: json['session_id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      scenarioName: json['scenario_name'] ?? '',
      difficulty: json['difficulty'] ?? '',
      completedAt: DateTime.parse(json['completed_at'] ?? DateTime.now().toIso8601String()),
      overallScore: json['overall_score'] ?? 0,
      empathyScore: json['empathy_score'] ?? 0,
      deEscalationScore: json['de_escalation_score'] ?? 0,
      communicationClarityScore: json['communication_clarity_score'] ?? 0,
      problemSolvingScore: json['problem_solving_score'] ?? 0,
      efficiencyScore: json['efficiency_score'] ?? 0,
      grade: json['grade'] ?? 'F',
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Achievement badge model
class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime? unlockedAt;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : null,
    );
  }

  AchievementBadge copyWith({DateTime? unlockedAt}) {
    return AchievementBadge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
