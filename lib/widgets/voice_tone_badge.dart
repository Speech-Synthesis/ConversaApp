import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small pill badge that shows the trainee's detected voice tone
/// and a confidence score out of 10.
///
/// Example: [🪄 monotone (5/10)]
class VoiceToneBadge extends StatelessWidget {
  final String emotion;
  final double confidence; // 0.0 – 1.0

  const VoiceToneBadge({
    super.key,
    required this.emotion,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final score = (confidence * 10).round().clamp(0, 10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪄', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            '$emotion ($score/10)',
            style: GoogleFonts.outfit(
              color: const Color(0xFF9D97FF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
