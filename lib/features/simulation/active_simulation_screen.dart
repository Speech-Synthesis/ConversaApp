import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/error_handler.dart';
import '../../models/scenario.dart';
import '../../widgets/emotion_badge.dart';
import '../../widgets/message_bubble.dart';
import '../../providers/api_provider.dart';
import 'feedback_screen.dart';

/// Live simulation conversation screen.
class ActiveSimulationScreen extends ConsumerStatefulWidget {
  final ScenarioSummary scenario;

  const ActiveSimulationScreen({super.key, required this.scenario});

  @override
  ConsumerState<ActiveSimulationScreen> createState() => _ActiveSimulationScreenState();
}

class _ActiveSimulationScreenState extends ConsumerState<ActiveSimulationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Session state
  String? _sessionId;
  String _customerName = 'Customer';
  String _currentEmotion = 'neutral';
  bool _emotionChanged = false;
  int _turnNumber = 0;
  List<String> _detectedTechniques = [];
  List<String> _detectedIssues = [];

  // Messages: {text, isTrainee, senderName, timestamp, voiceTone?, voiceScore?}
  final List<Map<String, dynamic>> _messages = [];

  bool _loading = true;
  bool _sending = false;
  bool _isRecording = false;
  bool _conversationComplete = false;
  String? _error;
  final int _timeoutSeconds = 90;
  int _elapsedSeconds = 0;

  // Timeout tracking
  final int _timeoutSeconds = 90;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startSimulation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiClientProvider).startSimulation(widget.scenario.scenarioId);
      if (mounted) {
        setState(() {
          _sessionId = result.sessionId;
          _customerName = result.customerName;
          _currentEmotion = result.initialEmotion;
          _loading = false;
          _messages.add({
            'text': result.openingMessage,
            'isTrainee': false,
            'senderName': _customerName,
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
        // Play customer opening message
        ref.read(voiceServiceProvider).synthesizeAndPlay(result.openingMessage,
            style: result.prosody['style']?.toString(),
            pitch: result.prosody['pitch']?.toString(),
            rate: result.prosody['rate']?.toString());
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Failed to start simulation'; });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sessionId == null || _sending) return;
    _textController.clear();

    setState(() {
      _sending = true;
      _elapsedSeconds = 0;
      _messages.add({
        'text': text,
        'isTrainee': true,
        'senderName': 'You',
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();

    // Start a timer to track elapsed seconds
    final timer = Stream.periodic(const Duration(seconds: 1), (count) => count + 1)
        .take(_timeoutSeconds)
        .listen((seconds) {
      if (mounted && _sending) {
        setState(() => _elapsedSeconds = seconds);
      }
    });

    try {
      final turn = await ref.read(apiClientProvider).sendResponse(_sessionId!, text).timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Request took too long');
        },
      );
      
      timer.cancel();
      
      if (mounted) {
        setState(() {
          _sending = false;
          _elapsedSeconds = 0;
          _currentEmotion = turn.emotionState;
          _emotionChanged = turn.emotionChanged;
          _turnNumber = turn.turnNumber;
          _detectedTechniques = turn.detectedTechniques;
          _detectedIssues = turn.detectedIssues;
          _conversationComplete = turn.conversationComplete;

          _messages.add({
            'text': turn.customerMessage,
            'isTrainee': false,
            'senderName': _customerName,
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();

        // Play customer response
        ref.read(voiceServiceProvider).synthesizeAndPlay(turn.customerMessage,
            style: turn.prosody['style']?.toString(),
            pitch: turn.prosody['pitch']?.toString(),
            rate: turn.prosody['rate']?.toString());

        // Auto-end if conversation is complete
        if (turn.conversationComplete && turn.goodbyeMessage != null) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _showEndDialog(autoEnd: true);
        }
      }
    } on TimeoutException catch (_) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _sending = false;
          _elapsedSeconds = 0;
        });
        _showTimeoutDialog();
      }
    } on ApiException catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _sending = false;
          _elapsedSeconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _sending = false;
          _elapsedSeconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to send response'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Voice recording — toggle on tap
  Future<void> _toggleRecording() async {
    debugPrint('[Mic] _toggleRecording called, _isRecording=$_isRecording');
    try {
      if (_isRecording) {
        await _stopRecordingAndProcess();
      } else {
        final hasPerm = await ref.read(voiceServiceProvider).hasPermission();
        debugPrint('[Mic] hasPermission=$hasPerm');
        if (!hasPerm) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Microphone permission denied'),
                  backgroundColor: Colors.redAccent),
            );
          }
          return;
        }
        await ref.read(voiceServiceProvider).startRecording();
        debugPrint('[Mic] Recording started');
        if (mounted) setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('[Mic] Error: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    final result = await ref.read(voiceServiceProvider).stopRecording();
    if (mounted) setState(() => _isRecording = false);

    if (result == null || result.bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No audio captured. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() { _sending = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transcribing ${result.bytes.length} bytes of audio...'),
          backgroundColor: const Color(0xFF2A2A3C),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // Keep audio bytes for voice analysis after transcription
      final audioBytes = result.bytes;
      final transcribed = await ref.read(voiceServiceProvider).transcribe(
        result.bytes,
        sessionId: _sessionId ?? '',
        filename: result.filename,
      );
      debugPrint('[Mic] Transcribed: "$transcribed"');
      if (transcribed.isNotEmpty) {
        // Reset _sending so _sendMessage's guard doesn't block
        if (mounted) setState(() { _sending = false; });
        // Track the message index so we can update it with voice analysis
        final msgIndex = _messages.length;
        await _sendMessage(transcribed);
        // Async voice analysis — updates the badge once result arrives
        _analyzeAndAttachTone(audioBytes, msgIndex);
      } else {
        if (mounted) {
          setState(() { _sending = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not transcribe audio. Please speak louder or try text.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Mic] Transcription error: $e');
      if (mounted) {
        setState(() { _sending = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Analyze voice and attach tone badge to the trainee message at [msgIndex].
  Future<void> _analyzeAndAttachTone(Uint8List audioBytes, int msgIndex) async {
    try {
      final analysis = await ref.read(voiceServiceProvider).analyzeVoice(audioBytes);
      if (analysis != null && mounted && msgIndex < _messages.length) {
        setState(() {
          _messages[msgIndex]['voiceTone'] = analysis.primaryEmotion;
          _messages[msgIndex]['voiceScore'] = analysis.emotionConfidence;
        });
      }
    } catch (e) {
      debugPrint('[Voice] Tone analysis failed: $e');
    }
  }

  void _showEndDialog({bool autoEnd = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          autoEnd ? 'Conversation Ended' : 'End Session',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          autoEnd
              ? 'The customer has ended the conversation. Was the issue resolved?'
              : 'Was the customer\'s issue resolved?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endSession(false);
            },
            child: Text('Unresolved',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endSession(true);
            },
            child: Text('Resolved',
                style: GoogleFonts.outfit(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(bool resolved) async {
    if (_sessionId == null) return;
    try {
      await ref.read(apiClientProvider).endSimulation(_sessionId!, resolutionAchieved: resolved);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              sessionId: _sessionId!,
              scenarioTitle: widget.scenario.title,
              scenario: widget.scenario,
            ),
          ),
        );
      }
    } catch (e) {
      // Even if end fails, navigate to feedback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              sessionId: _sessionId!,
              scenarioTitle: widget.scenario.title,
              scenario: widget.scenario,
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelCurrentOperation() async {
    if (mounted) {
      setState(() {
        _sending = false;
        _elapsedSeconds = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operation cancelled'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request Timed Out',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'The simulation did not respond within $_timeoutSeconds seconds. Would you like to retry or end the session?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEndDialog();
            },
            child: Text('End Session',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // User can try sending another message
            },
            child: Text('Continue',
                style: GoogleFonts.outfit(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);

    if (_loading) {
      return Scaffold(
        backgroundColor: surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: primary, strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Starting simulation...', style: GoogleFonts.outfit(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.outfit(color: Colors.white54)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startSimulation,
                child: Text('Retry', style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2A2A3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.scenario.title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$_customerName · Turn $_turnNumber',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          EmotionBadge(emotion: _currentEmotion, changed: _emotionChanged),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 24),
            onPressed: () => _showEndDialog(),
            tooltip: 'End Session',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: surface),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.transparent),
            ),
          ),
          Column(
            children: [
              // Techniques / issues bar
              if (_detectedTechniques.isNotEmpty || _detectedIssues.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF2A2A3C).withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      if (_detectedTechniques.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: _detectedTechniques
                                .map((t) => _techniqueChip(t, true))
                                .toList(),
                          ),
                        ),
                      if (_detectedIssues.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: _detectedIssues
                                .map((t) => _techniqueChip(t, false))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = _messages[index];
                    final voiceTone = msg['voiceTone'] as String?;
                    final voiceScore = msg['voiceScore'] != null
                        ? (msg['voiceScore'] as num).toDouble()
                        : null;
                    return MessageBubble(
                      text: msg['text'],
                      isTrainee: msg['isTrainee'],
                      senderName: msg['senderName'],
                      timestamp: msg['timestamp'],
                      voiceTone: msg['voiceTone'],
                      voiceScore: msg['voiceScore'] != null
                          ? (msg['voiceScore'] as num).toDouble()
                          : null,
                    );
                  },
                ),
              ),

              // Input area
              _buildInputArea(primary),
            ],
          ),

          // Recording overlay
          if (_isRecording) _buildRecordingOverlay(),
          
          // Loading/Sending overlay with cancel button
          if (_sending) _buildLoadingOverlay(),

          // Real-time coaching hints overlay
          if (!_sending && !_isRecording && _turnNumber > 0)
            _buildCoachingHintsOverlay(primary),
        ],
      ),
    );
  }

  Widget _techniqueChip(String label, bool isPositive) {
    final c = isPositive ? Colors.greenAccent : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: c,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A3C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [0, 1, 2]
              .map((i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.white54, shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                          delay: (i * 200).ms,
                          duration: 600.ms,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(duration: 600.ms, begin: 0.3, end: 1.0),
              const SizedBox(width: 12),
              Text('Recording... Tap mic to stop',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ).animate().fade().slideY(begin: 0.3, end: 0),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final remainingSeconds = _timeoutSeconds - _elapsedSeconds;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thinking...',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waiting for response',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$remainingSeconds seconds remaining',
                  style: GoogleFonts.outfit(
                    color: remainingSeconds <= 10 ? Colors.orange : Colors.white38,
                    fontSize: 12,
                    fontWeight: remainingSeconds <= 10 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _cancelCurrentOperation,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
        ),
      ),
    );
  }

  Widget _buildInputArea(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _sendMessage,
                enabled: !_conversationComplete,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mic button — tap to toggle recording
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _isRecording ? Colors.redAccent : Colors.white10),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.redAccent : Colors.white70,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  /// Build real-time coaching hints overlay
  Widget _buildCoachingHintsOverlay(Color primary) {
    String? hint;
    IconData hintIcon = Icons.lightbulb_outline;
    Color hintColor = Colors.amber;

    // Generate contextual coaching hints
    if (_detectedIssues.isNotEmpty) {
      // Show corrective hints for issues
      final issue = _detectedIssues.first.toLowerCase();
      if (issue.contains('empathy') || issue.contains('acknowledge')) {
        hint = 'Try acknowledging their frustration first';
        hintIcon = Icons.favorite_outline;
        hintColor = Colors.pink;
      } else if (issue.contains('question') || issue.contains('clarif')) {
        hint = 'Ask clarifying questions to understand better';
        hintIcon = Icons.help_outline;
        hintColor = Colors.orange;
      } else if (issue.contains('solution') || issue.contains('resolve')) {
        hint = 'Focus on offering a clear solution';
        hintIcon = Icons.check_circle_outline;
        hintColor = Colors.blue;
      } else {
        hint = _detectedIssues.first;
        hintColor = Colors.amber;
      }
    } else if (_detectedTechniques.isNotEmpty) {
      // Show positive reinforcement
      final technique = _detectedTechniques.first.toLowerCase();
      if (technique.contains('empathy')) {
        hint = 'Good — you\'re showing empathy';
        hintIcon = Icons.thumb_up_outlined;
        hintColor = Colors.greenAccent;
      } else if (technique.contains('question')) {
        hint = 'Good — you asked a clarifying question';
        hintIcon = Icons.question_answer_outlined;
        hintColor = Colors.greenAccent;
      } else if (technique.contains('solution')) {
        hint = 'Great — you offered a clear solution';
        hintIcon = Icons.task_alt;
        hintColor = Colors.greenAccent;
      } else {
        hint = 'Good technique: ${_detectedTechniques.first}';
        hintIcon = Icons.check_circle_outline;
        hintColor = Colors.greenAccent;
      }
    } else if (_currentEmotion == 'angry' || _currentEmotion == 'frustrated') {
      hint = 'Customer seems $_currentEmotion. Stay calm and empathetic';
      hintIcon = Icons.sentiment_dissatisfied_outlined;
      hintColor = Colors.orange;
    } else if (_currentEmotion == 'satisfied' || _currentEmotion == 'happy') {
      hint = 'Customer feeling positive. Keep it up!';
      hintIcon = Icons.sentiment_satisfied_alt_outlined;
      hintColor = Colors.greenAccent;
    }

    if (hint == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 90,
      right: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hintColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: hintColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(hintIcon, color: hintColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0),
    );
  }
}
