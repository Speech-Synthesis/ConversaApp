import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../simulation/scenario_list_screen.dart';

/// Entry screen: health check → navigate to scenario list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();
  bool _checking = true;
  bool _healthy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final ok = await _api.checkHealth();
      if (mounted) {
        setState(() {
          _checking = false;
          _healthy = ok;
          if (!ok) _error = 'Backend returned unhealthy status';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checking = false;
          _healthy = false;
          _error = e.toString();
        });
      }
    }
  }

  void _goToScenarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScenarioListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          // Ambient orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.12),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    duration: 4.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withOpacity(0.08),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    duration: 5.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.3, 1.3),
                    delay: 1.seconds),
          ),
          // Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic_rounded,
                        size: 56, color: primary),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          duration: 2000.ms),
                  const SizedBox(height: 24),
                  Text(
                    'ConversaVoice',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Customer Care Training Simulator',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 48),

                  // Status area
                  if (_checking)
                    Column(
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child:
                              CircularProgressIndicator(color: primary, strokeWidth: 3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connecting to backend...',
                          style:
                              GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConfig.backendUrl,
                          style:
                              GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                        ),
                      ],
                    )
                  else if (_healthy)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.greenAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Backend Connected',
                                style: GoogleFonts.outfit(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _goToScenarios,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primary, Color(0xFF8B83FF)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Start Training',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideY(begin: 0.3, end: 0),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off,
                                  color: Colors.redAccent, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                'Backend Unavailable',
                                style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppConfig.backendUrl,
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white30,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _checkHealth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Retry',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
