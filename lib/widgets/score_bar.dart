import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated horizontal score bar for analysis screens.
class ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final Color? color;

  const ScoreBar({
    super.key,
    required this.label,
    required this.score,
    this.maxScore = 10,
    this.color,
  });

  Color _defaultColor() {
    final ratio = score / maxScore;
    if (ratio >= 0.8) return Colors.greenAccent;
    if (ratio >= 0.6) return Colors.tealAccent;
    if (ratio >= 0.4) return Colors.amber;
    if (ratio >= 0.2) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? _defaultColor();
    final ratio = (score / maxScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.withValues(alpha: 0.7), c],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '$score/$maxScore',
              style: GoogleFonts.outfit(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
