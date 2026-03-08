/// Full LLM-powered analysis of a completed session.
class AnalysisResponse {
  final String sessionId;
  final String scenarioId;
  final int overallScore;
  final int empathyScore;
  final int deEscalationScore;
  final int communicationClarityScore;
  final int problemSolvingScore;
  final int efficiencyScore;
  final bool deEscalationSuccess;
  final bool resolutionAchieved;
  final String customerSatisfactionPredicted;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final List<String> specificFeedback;
  final List<String> recommendedTraining;
  final int turnCount;
  final double durationSeconds;
  final int emotionChanges;

  AnalysisResponse({
    required this.sessionId,
    required this.scenarioId,
    required this.overallScore,
    required this.empathyScore,
    required this.deEscalationScore,
    required this.communicationClarityScore,
    required this.problemSolvingScore,
    required this.efficiencyScore,
    required this.deEscalationSuccess,
    required this.resolutionAchieved,
    required this.customerSatisfactionPredicted,
    required this.strengths,
    required this.areasForImprovement,
    required this.specificFeedback,
    required this.recommendedTraining,
    required this.turnCount,
    required this.durationSeconds,
    required this.emotionChanges,
  });

  /// Letter grade from overall score.
  String get grade {
    if (overallScore >= 9) return 'A';
    if (overallScore >= 8) return 'B+';
    if (overallScore >= 7) return 'B';
    if (overallScore >= 6) return 'C+';
    if (overallScore >= 5) return 'C';
    if (overallScore >= 4) return 'D';
    return 'F';
  }

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      sessionId: json['session_id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      overallScore: json['overall_score'] ?? 0,
      empathyScore: json['empathy_score'] ?? 0,
      deEscalationScore: json['de_escalation_score'] ?? 0,
      communicationClarityScore: json['communication_clarity_score'] ?? 0,
      problemSolvingScore: json['problem_solving_score'] ?? 0,
      efficiencyScore: json['efficiency_score'] ?? 0,
      deEscalationSuccess: json['de_escalation_success'] ?? false,
      resolutionAchieved: json['resolution_achieved'] ?? false,
      customerSatisfactionPredicted:
          json['customer_satisfaction_predicted'] ?? 'Unknown',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement:
          List<String>.from(json['areas_for_improvement'] ?? []),
      specificFeedback: List<String>.from(json['specific_feedback'] ?? []),
      recommendedTraining:
          List<String>.from(json['recommended_training'] ?? []),
      turnCount: json['turn_count'] ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      emotionChanges: json['emotion_changes'] ?? 0,
    );
  }
}

/// Quick score without full LLM analysis (fallback).
class QuickScoreResponse {
  final int empathyScore;
  final int deEscalationScore;
  final int efficiencyScore;
  final int overallScore;
  final int emotionImprovement;
  final List<String> techniquesUsed;
  final bool resolutionAchieved;

  QuickScoreResponse({
    required this.empathyScore,
    required this.deEscalationScore,
    required this.efficiencyScore,
    required this.overallScore,
    required this.emotionImprovement,
    required this.techniquesUsed,
    required this.resolutionAchieved,
  });

  String get grade {
    if (overallScore >= 9) return 'A';
    if (overallScore >= 8) return 'B+';
    if (overallScore >= 7) return 'B';
    if (overallScore >= 6) return 'C+';
    if (overallScore >= 5) return 'C';
    if (overallScore >= 4) return 'D';
    return 'F';
  }

  factory QuickScoreResponse.fromJson(Map<String, dynamic> json) {
    return QuickScoreResponse(
      empathyScore: json['empathy_score'] ?? 0,
      deEscalationScore: json['de_escalation_score'] ?? 0,
      efficiencyScore: json['efficiency_score'] ?? 0,
      overallScore: json['overall_score'] ?? 0,
      emotionImprovement: json['emotion_improvement'] ?? 0,
      techniquesUsed: List<String>.from(json['techniques_used'] ?? []),
      resolutionAchieved: json['resolution_achieved'] ?? false,
    );
  }
}
