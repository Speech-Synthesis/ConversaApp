import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/progress_provider.dart';
import '../../models/progress_result.dart' show ProgressResult, AchievementBadge;

/// Screen displaying trainee progress, stats, and achievements
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);

    final resultsAsync = ref.watch(progressResultsProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Progress',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                streakAsync.when(
                  data: (streak) => _buildStreakCard(streak, primary),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Stats overview
                _buildStatsOverview(results, primary),
                const SizedBox(height: 24),

                // Score trend chart
                _buildScoreTrendSection(results, primary),
                const SizedBox(height: 24),

                // Skills radar chart
                _buildSkillsRadarSection(results, primary),
                const SizedBox(height: 24),

                // Badges section
                badgesAsync.when(
                  data: (badges) => _buildBadgesSection(badges, primary),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Recent simulations
                _buildRecentSimulations(results, primary),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Failed to load progress',
            style: GoogleFonts.outfit(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assessment_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No progress yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first simulation to start tracking',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streak, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.2), primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Keep it up! Practice daily to improve',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(List<ProgressResult> results, Color primary) {
    final totalSims = results.length;
    final avgScore = results.map((r) => r.overallScore).reduce((a, b) => a + b) / totalSims;
    final gradeA = results.where((r) => r.grade == 'A').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Sims', totalSims.toString(), Icons.play_circle_outline, primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Avg Score', avgScore.toStringAsFixed(1), Icons.star_outline, Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Grade A', gradeA.toString(), Icons.school_outlined, Colors.greenAccent)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTrendSection(List<ProgressResult> results, Color primary) {
    // Get last 10 results for the chart
    final chartData = results.reversed.take(10).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Trend',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                        return Text(
                          '#${value.toInt() + 1}',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 10,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.overallScore.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsRadarSection(List<ProgressResult> results, Color primary) {
    // Calculate average scores for each skill
    final avgEmpathy = results.map((r) => r.empathyScore).reduce((a, b) => a + b) / results.length;
    final avgDeescalation = results.map((r) => r.deEscalationScore).reduce((a, b) => a + b) / results.length;
    final avgCommunication = results.map((r) => r.communicationClarityScore).reduce((a, b) => a + b) / results.length;
    final avgProblemSolving = results.map((r) => r.problemSolvingScore).reduce((a, b) => a + b) / results.length;
    final avgEfficiency = results.map((r) => r.efficiencyScore).reduce((a, b) => a + b) / results.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills Overview',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSkillBar('Empathy', avgEmpathy, primary),
              const SizedBox(height: 12),
              _buildSkillBar('De-escalation', avgDeescalation, Colors.orange),
              const SizedBox(height: 12),
              _buildSkillBar('Communication', avgCommunication, Colors.cyan),
              const SizedBox(height: 12),
              _buildSkillBar('Problem Solving', avgProblemSolving, Colors.greenAccent),
              const SizedBox(height: 12),
              _buildSkillBar('Efficiency', avgEfficiency, Colors.amber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
            ),
            Text(
              value.toStringAsFixed(1),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 10,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(List<AchievementBadge> badges, Color primary) {
    final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
    final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${unlockedBadges.length}/${badges.length}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...unlockedBadges.map((b) => _buildBadge(b, true, primary)),
            ...lockedBadges.map((b) => _buildBadge(b, false, primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(AchievementBadge badge, bool unlocked, Color primary) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked 
            ? primary.withValues(alpha: 0.15) 
            : const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked 
              ? primary.withValues(alpha: 0.4) 
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            badge.icon,
            style: TextStyle(
              fontSize: 32,
              color: unlocked ? null : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? Colors.white : Colors.white38,
            ),
          ),
          if (unlocked && badge.unlockedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d').format(badge.unlockedAt!),
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSimulations(List<ProgressResult> results, Color primary) {
    final recent = results.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Simulations',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...recent.map((r) => _buildResultCard(r, primary)),
      ],
    );
  }

  Widget _buildResultCard(ProgressResult result, Color primary) {
    Color difficultyColor;
    switch (result.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = Colors.greenAccent;
        break;
      case 'medium':
        difficultyColor = Colors.amber;
        break;
      case 'hard':
        difficultyColor = Colors.orange;
        break;
      case 'expert':
        difficultyColor = Colors.redAccent;
        break;
      default:
        difficultyColor = Colors.blueGrey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.scenarioName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.difficulty.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: difficultyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(result.completedAt),
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
              ),
              Row(
                children: [
                  Text(
                    'Score: ',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                  ),
                  Text(
                    '${result.overallScore}/10',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.grade,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
