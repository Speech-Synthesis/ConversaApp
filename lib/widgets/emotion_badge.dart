import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pill-shaped badge showing the current customer emotion state.
class EmotionBadge extends StatelessWidget {
  final String emotion;
  final bool changed;

  const EmotionBadge({
    super.key,
    required this.emotion,
    this.changed = false,
  });

  Color _color() {
    switch (emotion.toLowerCase()) {
      case 'angry':
      case 'furious':
        return Colors.redAccent;
      case 'frustrated':
      case 'irritated':
        return Colors.orange;
      case 'anxious':
      case 'worried':
      case 'stressed':
        return Colors.amber;
      case 'neutral':
        return Colors.blueGrey;
      case 'calm':
      case 'satisfied':
        return Colors.teal;
      case 'happy':
      case 'grateful':
      case 'relieved':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _icon() {
    switch (emotion.toLowerCase()) {
      case 'angry':
      case 'furious':
        return Icons.sentiment_very_dissatisfied;
      case 'frustrated':
      case 'irritated':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
      case 'worried':
      case 'stressed':
        return Icons.sentiment_neutral;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'calm':
      case 'satisfied':
        return Icons.sentiment_satisfied;
      case 'happy':
      case 'grateful':
      case 'relieved':
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: c, size: 16),
          const SizedBox(width: 6),
          Text(
            emotion,
            style: GoogleFonts.outfit(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (changed) ...[
            const SizedBox(width: 4),
            Icon(Icons.trending_flat, color: c, size: 14),
          ],
        ],
      ),
    );
  }
}
