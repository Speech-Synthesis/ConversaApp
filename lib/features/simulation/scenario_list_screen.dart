import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/api_client.dart';
import '../../core/error_handler.dart';
import '../../models/scenario.dart';
import 'active_simulation_screen.dart';

/// Screen listing available training scenarios with category/difficulty filters.
class ScenarioListScreen extends StatefulWidget {
  const ScenarioListScreen({super.key});

  @override
  State<ScenarioListScreen> createState() => _ScenarioListScreenState();
}

class _ScenarioListScreenState extends State<ScenarioListScreen> {
  final ApiClient _api = ApiClient();
  List<ScenarioSummary> _scenarios = [];
  List<String> _categories = [];
  bool _loading = true;
  String? _error;

  String? _selectedCategory;
  String? _selectedDifficulty;
  final List<String> _difficulties = ['easy', 'medium', 'hard', 'expert'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getScenarios(
            category: _selectedCategory, difficulty: _selectedDifficulty),
        _api.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _scenarios = results[0] as List<ScenarioSummary>;
          if (_categories.isEmpty) {
            _categories = results[1] as List<String>;
          }
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load scenarios'; });
    }
  }

  void _startScenario(ScenarioSummary scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveSimulationScreen(scenario: scenario),
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent;
      case 'medium':
        return Colors.amber;
      case 'hard':
        return Colors.orange;
      case 'expert':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [surface.withOpacity(0.95), surface.withOpacity(0.8)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Training Scenarios',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          // Ambient orb
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
          ),
          Column(
            children: [
              // Category tabs
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip('All', _selectedCategory == null, () {
                        setState(() => _selectedCategory = null);
                        _loadData();
                      }),
                      ..._categories.map((c) => _filterChip(
                            c,
                            _selectedCategory == c,
                            () {
                              setState(() => _selectedCategory = c);
                              _loadData();
                            },
                          )),
                    ],
                  ),
                ),
              // Difficulty filter
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('All Levels', _selectedDifficulty == null, () {
                      setState(() => _selectedDifficulty = null);
                      _loadData();
                    }),
                    ..._difficulties.map((d) => _filterChip(
                          d[0].toUpperCase() + d.substring(1),
                          _selectedDifficulty == d,
                          () {
                            setState(() => _selectedDifficulty = d);
                            _loadData();
                          },
                          color: _difficultyColor(d),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Scenario list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 3))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent, size: 40),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54)),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _loadData,
                                  child: Text('Retry',
                                      style: GoogleFonts.outfit(
                                          color: primary,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          )
                        : _scenarios.isEmpty
                            ? Center(
                                child: Text('No scenarios found',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: _scenarios.length,
                                itemBuilder: (_, i) =>
                                    _buildScenarioCard(_scenarios[i], primary),
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c.withOpacity(0.5) : Colors.white10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: selected ? c : Colors.white54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(ScenarioSummary s, Color primary) {
    final dc = _difficultyColor(s.difficulty);
    return GestureDetector(
      onTap: () => _startScenario(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + difficulty badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dc.withOpacity(0.4)),
                  ),
                  child: Text(
                    s.difficulty.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: dc,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.outfit(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            // Meta row
            Row(
              children: [
                _metaChip(Icons.category_outlined, s.category),
                const SizedBox(width: 8),
                _metaChip(Icons.mood, s.personaEmotion),
                const SizedBox(width: 8),
                _metaChip(Icons.timer_outlined, '${s.estimatedDuration}m'),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    color: primary.withOpacity(0.5), size: 14),
              ],
            ),
            if (s.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: s.tags
                    .take(4)
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.outfit(
                                color: primary.withOpacity(0.7), fontSize: 10),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white30, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
