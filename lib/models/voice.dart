/// Voice analysis result from /api/simulation/analyze-voice.
class VoiceAnalysisResponse {
  final bool analysisSuccess;
  final String primaryEmotion;
  final String? secondaryEmotion;
  final double emotionConfidence;
  final Map<String, int> deliveryScores;
  final Map<String, double> acousticFeatures;
  final String? errorMessage;

  VoiceAnalysisResponse({
    required this.analysisSuccess,
    required this.primaryEmotion,
    this.secondaryEmotion,
    required this.emotionConfidence,
    required this.deliveryScores,
    required this.acousticFeatures,
    this.errorMessage,
  });

  factory VoiceAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return VoiceAnalysisResponse(
      analysisSuccess: json['analysis_success'] ?? false,
      primaryEmotion: json['primary_emotion'] ?? 'unknown',
      secondaryEmotion: json['secondary_emotion'],
      emotionConfidence:
          (json['emotion_confidence'] as num?)?.toDouble() ?? 0.0,
      deliveryScores: (json['delivery_scores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)) ??
          {},
      acousticFeatures: (json['acoustic_features'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0)) ??
          {},
      errorMessage: json['error_message'],
    );
  }
}
