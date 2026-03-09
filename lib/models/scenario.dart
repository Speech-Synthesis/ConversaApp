import 'package:flutter/material.dart';

/// Summary of a training scenario for listing.
class ScenarioSummary {
  final String scenarioId;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String personaEmotion;
  final String personaPersonality;
  final String? voiceGender; // Added for gender/voice matching
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
    this.voiceGender,
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
      voiceGender: json['voice_gender'], // Can be 'male', 'female', or null
      estimatedDuration: json['estimated_duration'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario_id': scenarioId,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'persona_emotion': personaEmotion,
      'persona_personality': personaPersonality,
      'voice_gender': voiceGender,
      'estimated_duration': estimatedDuration,
      'tags': tags,
    };
  }

  /// Get icon for persona gender
  IconData getGenderIcon() {
    if (voiceGender == null) return Icons.person;
    switch (voiceGender!.toLowerCase()) {
      case 'male':
        return Icons.man;
      case 'female':
        return Icons.woman;
      default:
        return Icons.person;
    }
  }
}
