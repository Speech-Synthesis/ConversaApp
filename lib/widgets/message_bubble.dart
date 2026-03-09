import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'voice_tone_badge.dart';

/// Chat bubble for customer or trainee messages.
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isTrainee;
  final DateTime? timestamp;
  final String? senderName;

  /// Detected voice tone label (e.g., "monotone", "confident").
  /// Only present for voice-recorded trainee messages.
  final String? voiceTone;

  /// Voice tone quality score (0.0 – 1.0). Displayed as x/10.
  final double? voiceScore;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isTrainee,
    this.timestamp,
    this.senderName,
    this.voiceTone,
    this.voiceScore,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6C63FF);
    final bubbleColor = isTrainee
        ? primaryColor.withValues(alpha: 0.2)
        : const Color(0xFF2A2A3C);
    final borderColor = isTrainee
        ? primaryColor.withValues(alpha: 0.3)
        : Colors.white10;

    return Align(
      alignment: isTrainee ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isTrainee ? 20 : 5),
            bottomRight: Radius.circular(isTrainee ? 5 : 20),
          ),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderName!,
                      style: GoogleFonts.outfit(
                        color: isTrainee ? primaryColor : Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (voiceTone != null && voiceScore != null) ...[
                      const SizedBox(width: 8),
                      VoiceToneBadge(
                        tone: voiceTone!,
                        score: voiceScore!,
                      ),
                    ],
                  ],
                ),
              ),
            Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(timestamp!),
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
