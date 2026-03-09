import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/api_client.dart';
import '../../models/analysis.dart';
import '../../models/scenario.dart';
import '../../widgets/score_bar.dart';
import '../../services/progress_tracking_service.dart';
import 'scenario_list_screen.dart';

/// Performance report screen after a simulation ends.
class FeedbackScreen extends StatefulWidget {
  final String sessionId;
  final String scenarioTitle;
  final ScenarioSummary scenario;

  const FeedbackScreen({
    super.key,
    required this.sessionId,
    required this.scenarioTitle,
    required this.scenario,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiClient _api = ApiClient();
  final ProgressTrackingService _progressService = ProgressTrackingService();
  AnalysisResponse? _analysis;
  QuickScoreResponse? _quickScore;
  bool _loading = true;
  bool _isQuickFallback = false;
  String? _error;
  String? _transcript;

  Future<void> _saveProgressResult(AnalysisResponse analysis) async {
    try {
      await _progressService.saveResult(
        analysis: analysis,
        scenario: widget.scenario,
      );
    } catch (e) {
      // Silently fail - progress tracking is not critical
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final analysis = await _api.getAnalysis(widget.sessionId);
      if (mounted) {
        // Save progress result
        await _saveProgressResult(analysis);
        setState(() {
          _analysis = analysis;
          _loading = false;
        });
      }
    } catch (_) {
      // Fallback to quick score
      try {
        final quick = await _api.getQuickScore(widget.sessionId);
        if (mounted) {
          setState(() {
            _quickScore = quick;
            _isQuickFallback = true;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Could not load analysis';
          });
        }
      }
    }
  }

  Future<void> _viewTranscript() async {
    if (_transcript != null) {
      _showTranscriptDialog();
      return;
    }
    try {
      final text = await _api.getTranscript(widget.sessionId);
      _transcript = text;
      _showTranscriptDialog();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not load transcript'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showTranscriptDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Transcript',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Text(
            _transcript ?? 'No transcript available',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Close', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _tryAgain() {
    Navigator.pop(context); // Back to scenario list / will restart
  }

  void _newScenario() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ScenarioListScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: surface,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 3))
          : _error != null
              ? _buildErrorState(primary)
              : _buildReport(primary),
    );
  }

  Widget _buildErrorState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.outfit(color: Colors.white54)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadAnalysis,
            child: Text('Retry',
                style: GoogleFonts.outfit(
                    color: primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _newScenario,
            child: Text('New Scenario',
                style: GoogleFonts.outfit(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(Color primary) {
    final overall = _analysis?.overallScore ?? _quickScore?.overallScore ?? 0;
    final grade = _analysis?.grade ?? _quickScore?.grade ?? '?';
    final resolved =
        _analysis?.resolutionAchieved ?? _quickScore?.resolutionAchieved ?? false;
    final deEscSuccess = _analysis?.deEscalationSuccess ?? false;

    return Stack(
      children: [
        // Background orbs
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_rounded,
                        color: primary, size: 28),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Performance ',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'Report',
                            style: GoogleFonts.outfit(
                                color: primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 4),
                Text("Here's how you did in this simulation",
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),

                if (_isQuickFallback)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Quick analysis (detailed report unavailable)',
                        style: GoogleFonts.outfit(
                            color: Colors.amber, fontSize: 11),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Grade card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.15),
                        const Color(0xFF2A2A3C),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      Text(grade,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold))
                        .animate().scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 500.ms),
                      Text('Overall Score: $overall/10',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statusBadge(
                              'Resolution',
                              resolved ? 'Achieved' : 'Not Achieved',
                              resolved),
                          const SizedBox(width: 12),
                          if (_analysis != null)
                            _statusBadge(
                                'De-escalation',
                                deEscSuccess ? 'Success' : 'Failed',
                                deEscSuccess),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Content Analysis scores (full analysis only)
                if (_analysis != null) ...[
                  _sectionHeader(Icons.analytics_outlined, 'Content Analysis'),
                  _scoreCard([
                    ScoreBar(
                        label: 'Empathy', score: _analysis!.empathyScore),
                    ScoreBar(
                        label: 'De-escalation',
                        score: _analysis!.deEscalationScore),
                    ScoreBar(
                        label: 'Communication',
                        score: _analysis!.communicationClarityScore),
                    ScoreBar(
                        label: 'Problem Solving',
                        score: _analysis!.problemSolvingScore),
                    ScoreBar(
                        label: 'Efficiency',
                        score: _analysis!.efficiencyScore),
                  ]),
                  const SizedBox(height: 16),
                ] else if (_quickScore != null) ...[
                  _sectionHeader(Icons.analytics_outlined, 'Quick Scores'),
                  _scoreCard([
                    ScoreBar(
                        label: 'Empathy', score: _quickScore!.empathyScore),
                    ScoreBar(
                        label: 'De-escalation',
                        score: _quickScore!.deEscalationScore),
                    ScoreBar(
                        label: 'Efficiency',
                        score: _quickScore!.efficiencyScore),
                  ]),
                  const SizedBox(height: 16),
                  if (_quickScore!.techniquesUsed.isNotEmpty) ...[
                    _sectionHeader(
                        Icons.check_circle_outline, 'Techniques Used'),
                    _listCard(_quickScore!.techniquesUsed
                        .map((t) => '✓ $t')
                        .toList()),
                    const SizedBox(height: 16),
                  ],
                ],

                // Strengths
                if (_analysis != null && _analysis!.strengths.isNotEmpty) ...[
                  _sectionHeader(Icons.thumb_up_outlined, 'Strengths'),
                  _listCard(
                      _analysis!.strengths.map((s) => '• $s').toList()),
                  const SizedBox(height: 16),
                ],

                // Areas for improvement
                if (_analysis != null &&
                    _analysis!.areasForImprovement.isNotEmpty) ...[
                  _sectionHeader(
                      Icons.trending_up, 'Areas for Improvement'),
                  _listCard(_analysis!.areasForImprovement
                      .map((s) => '📝 $s')
                      .toList()),
                  const SizedBox(height: 16),
                ],

                // Specific feedback
                if (_analysis != null &&
                    _analysis!.specificFeedback.isNotEmpty) ...[
                  _sectionHeader(Icons.lightbulb_outline, 'Specific Feedback'),
                  ..._analysis!.specificFeedback.map((f) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.15)),
                        ),
                        child: Text(f,
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5)),
                      )),
                  const SizedBox(height: 16),
                ],

                // Recommended training
                if (_analysis != null &&
                    _analysis!.recommendedTraining.isNotEmpty) ...[
                  _sectionHeader(
                      Icons.school_outlined, 'Recommended Training'),
                  _listCard(_analysis!.recommendedTraining
                      .map((t) => '📚 $t')
                      .toList()),
                  const SizedBox(height: 16),
                ],

                // Session stats
                if (_analysis != null) ...[
                  _sectionHeader(
                      Icons.bar_chart_rounded, 'Session Statistics'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3C),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        _statItem('Total Turns', '${_analysis!.turnCount}'),
                        _statItem(
                            'Duration',
                            '${_analysis!.durationSeconds.toInt()}s'),
                        _statItem('Emotion Changes',
                            '${_analysis!.emotionChanges}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        Icons.replay_rounded,
                        'Try Again',
                        Colors.blueAccent,
                        _tryAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        Icons.description_outlined,
                        'View Transcript',
                        Colors.tealAccent,
                        _viewTranscript,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        Icons.add_circle_outline,
                        'New Scenario',
                        primary,
                        _newScenario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _scoreCard(List<Widget> bars) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: bars),
    ).animate().fadeIn();
  }

  Widget _listCard(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(item,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.4)),
                ))
            .toList(),
      ),
    ).animate().fadeIn();
  }

  Widget _statusBadge(String label, String value, bool success) {
    final c = success ? Colors.greenAccent : Colors.redAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        Icon(success ? Icons.check_circle : Icons.cancel,
            color: c, size: 14),
        const SizedBox(width: 3),
        Text(value,
            style: GoogleFonts.outfit(
                color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
