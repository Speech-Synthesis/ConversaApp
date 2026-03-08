/// Response after starting a simulation.
class StartSimulationResponse {
  final String sessionId;
  final String scenarioId;
  final String scenarioTitle;
  final String customerName;
  final String initialEmotion;
  final String openingMessage;
  final Map<String, dynamic> prosody;

  StartSimulationResponse({
    required this.sessionId,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.customerName,
    required this.initialEmotion,
    required this.openingMessage,
    required this.prosody,
  });

  factory StartSimulationResponse.fromJson(Map<String, dynamic> json) {
    return StartSimulationResponse(
      sessionId: json['session_id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      scenarioTitle: json['scenario_title'] ?? '',
      customerName: json['customer_name'] ?? 'Customer',
      initialEmotion: json['initial_emotion'] ?? 'neutral',
      openingMessage: json['opening_message'] ?? '',
      prosody: Map<String, dynamic>.from(json['prosody'] ?? {}),
    );
  }
}

/// Response from a single simulation turn.
class SimulationTurnResponse {
  final String customerMessage;
  final String emotionState;
  final bool emotionChanged;
  final String? previousEmotion;
  final Map<String, dynamic> prosody;
  final int turnNumber;
  final List<String> detectedTechniques;
  final List<String> detectedIssues;
  final bool conversationComplete;
  final bool approachingEnd;
  final String? endingType;
  final String? goodbyeMessage;

  SimulationTurnResponse({
    required this.customerMessage,
    required this.emotionState,
    required this.emotionChanged,
    this.previousEmotion,
    required this.prosody,
    required this.turnNumber,
    required this.detectedTechniques,
    required this.detectedIssues,
    this.conversationComplete = false,
    this.approachingEnd = false,
    this.endingType,
    this.goodbyeMessage,
  });

  factory SimulationTurnResponse.fromJson(Map<String, dynamic> json) {
    return SimulationTurnResponse(
      customerMessage: json['customer_message'] ?? '',
      emotionState: json['emotion_state'] ?? 'neutral',
      emotionChanged: json['emotion_changed'] ?? false,
      previousEmotion: json['previous_emotion'],
      prosody: Map<String, dynamic>.from(json['prosody'] ?? {}),
      turnNumber: json['turn_number'] ?? 0,
      detectedTechniques: List<String>.from(json['detected_techniques'] ?? []),
      detectedIssues: List<String>.from(json['detected_issues'] ?? []),
      conversationComplete: json['conversation_complete'] ?? false,
      approachingEnd: json['approaching_end'] ?? false,
      endingType: json['ending_type'],
      goodbyeMessage: json['goodbye_message'],
    );
  }
}

/// Summary of a simulation session.
class SessionSummary {
  final String sessionId;
  final String scenarioId;
  final String scenarioTitle;
  final String? traineeId;
  final String status;
  final int totalTurns;
  final double? durationSeconds;
  final String? finalEmotion;
  final bool resolutionAchieved;
  final int emotionChanges;

  SessionSummary({
    required this.sessionId,
    required this.scenarioId,
    required this.scenarioTitle,
    this.traineeId,
    required this.status,
    required this.totalTurns,
    this.durationSeconds,
    this.finalEmotion,
    required this.resolutionAchieved,
    required this.emotionChanges,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['session_id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      scenarioTitle: json['scenario_title'] ?? '',
      traineeId: json['trainee_id'],
      status: json['status'] ?? 'unknown',
      totalTurns: json['total_turns'] ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      finalEmotion: json['final_emotion'],
      resolutionAchieved: json['resolution_achieved'] ?? false,
      emotionChanges: json['emotion_changes'] ?? 0,
    );
  }
}
