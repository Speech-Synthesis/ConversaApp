import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pill-shaped badge showing the trainee's detected voice tone and score.
///
/// Displays something like: 🎵 confident (8/10)
class VoiceToneBadge extends StatelessWidget {
  /// Detected primary emotion from voice analysis.
  final String tone;

  /// Confidence / quality score (0.0 – 1.0), displayed as x/10.
  final double score;

  const VoiceToneBadge({
    super.key,
    required this.tone,
    required this.score,
  });

  /// Map tone label to a quality color.
  Color _color() {
    switch (tone.toLowerCase()) {
      case 'confident':
      case 'calm':
      case 'enthusiastic':
        return Colors.greenAccent;
      case 'empathetic':
      case 'warm':
        return Colors.tealAccent;
      case 'neutral':
      case 'monotone':
      case 'flat':
        return Colors.amber;
      case 'stressed':
      case 'anxious':
      case 'nervous':
        return Colors.orange;
      case 'angry':
      case 'aggressive':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    final displayScore = (score * 10).round().clamp(0, 10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_rounded, color: c, size: 13),
          const SizedBox(width: 4),
          Text(
            '$tone ($displayScore/10)',
            style: GoogleFonts.outfit(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
