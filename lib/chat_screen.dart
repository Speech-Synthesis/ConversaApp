import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'api_service.dart';

import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final ApiService _apiService = ApiService(); // Single instance
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isTyping = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
      _isTyping = false;
    });
    _scrollToBottom();
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

  // --- Text Chat Flow ---
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addMessage(text, isUser: true);

    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiService.chat(text);

      if (mounted) {
        final responseText = response['response'] ?? 'No response from server.';
        final style = response['style'];
        _addMessage(responseText, isUser: false);

        // Auto-play TTS for the response
        _playTTS(responseText, style: style);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 404) {
          _addMessage('[!] Chat endpoint not found. Is the backend deployed?', isUser: false);
        } else {
          _addMessage('[!] Server error: ${e.message}', isUser: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _addMessage('[!] Could not reach the server. Check your connection.', isUser: false);
      }
    }
  }

  // --- Voice Recording Flow ---
  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        // Record to a stream of bytes (web-compatible)
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '', // Empty path for web (uses in-memory)
        );
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start recording: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording failed — no audio captured')),
          );
        }
        return;
      }

      // Show "Processing voice..." indicator
      _addMessage('Voice message', isUser: true);
      setState(() {
        _isTyping = true;
      });
      _scrollToBottom();

      // Read the recorded file as bytes
      // On web, 'path' is a blob URL; we need to fetch it
      Uint8List audioBytes;
      try {
        final uri = Uri.parse(path);
        final response = await _fetchAudioBytes(uri);
        audioBytes = response;
      } catch (e) {
        // Fallback: try reading directly
        print('Error reading audio: $e');
        if (mounted) {
          setState(() { _isTyping = false; });
          _addMessage("Could not process audio: $e", isUser: false);
        }
        return;
      }

      // Step 1: Transcribe audio → text
      String transcribedText;
      try {
        transcribedText = await _apiService.transcribe(audioBytes);
      } on ApiException catch (e) {
        if (mounted) {
          setState(() { _isTyping = false; });
          if (e.statusCode == 404) {
            _addMessage('[!] Voice transcription is not available on this server. Try typing your message instead.', isUser: false);
          } else {
            _addMessage('[!] Transcription error: ${e.message}', isUser: false);
          }
        }
        return;
      }

      if (mounted && transcribedText.isNotEmpty) {
        // Update the user message with transcribed text
        setState(() {
          _messages.last['text'] = '"$transcribedText"';
        });

        // Step 2: Send transcribed text to chat
        try {
          final chatResponse = await _apiService.chat(transcribedText);

          if (mounted) {
            final responseText = chatResponse['response'] ?? 'No response.';
            final style = chatResponse['style'];
            _addMessage(responseText, isUser: false);

            // Step 3: Play TTS for the response
            _playTTS(responseText, style: style);
          }
        } on ApiException catch (e) {
          if (mounted) {
            setState(() { _isTyping = false; });
            _addMessage('[!] Chat error: ${e.message}', isUser: false);
          }
        }
      } else if (mounted) {
        setState(() { _isTyping = false; });
        _addMessage('Could not transcribe audio. Please try again.', isUser: false);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isTyping = false;
      });
      if (mounted) {
        _addMessage('[!] Voice processing error. Please try again.', isUser: false);
      }
    }
  }

  // Fetch audio bytes from a blob URL (web) or file path
  Future<Uint8List> _fetchAudioBytes(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to fetch audio: ${response.statusCode}');
  }

  // --- TTS Playback ---
  Future<void> _playTTS(String text, {String? style}) async {
    try {
      final audioUrl = await _apiService.synthesize(text, style: style);
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('TTS playback error: $e');
      // TTS is optional — don't block the UI if it fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Theme Colors
    final surfaceColor = const Color(0xFF1E1E2E);
    final primaryColor = const Color(0xFF6C63FF);
    final bubbleUser = primaryColor.withOpacity(0.2);
    final bubbleBot = const Color(0xFF2A2A3C);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surfaceColor.withOpacity(0.95),
                surfaceColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.graphic_eq, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'ConversaVoice',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: surfaceColor),

          // Ambient Gradient Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.15),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 4.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3), delay: 1.seconds),
          ),
          Positioned(
            top: 150,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.05),
              ),
            ),
          ),

          // Blur Filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(primaryColor)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingIndicator(bubbleBot);
                          }
                          final msg = _messages[index];
                          return _buildMessageBubble(
                            msg['text'],
                            msg['isUser'],
                            msg['timestamp'],
                            bubbleUser,
                            bubbleBot,
                            primaryColor,
                          );
                        },
                      ),
              ),
              _buildInputArea(surfaceColor, primaryColor),
            ],
          ),

          // Recording overlay
          if (_isRecording)
            _buildRecordingOverlay(primaryColor),
        ],
      ),
    );
  }

  // --- Recording Overlay ---
  Widget _buildRecordingOverlay(Color primaryColor) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .fade(duration: 600.ms, begin: 0.3, end: 1.0),
              const SizedBox(width: 12),
              Text(
                'Recording... Release to send',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fade().slideY(begin: 0.3, end: 0),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 48, color: primaryColor),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms),
            
            const SizedBox(height: 24),
            Text(
              "Welcome to ConversaVoice",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 8),
            Text(
              "Type a message or hold the mic to speak",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 14,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0, delay: 100.ms),
            
            const SizedBox(height: 48),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip("Explain AI", Icons.lightbulb_outline, primaryColor),
                _buildSuggestionChip("Tell me a fun fact", Icons.emoji_emotions_outlined, primaryColor),
                _buildSuggestionChip("Write a poem", Icons.edit_outlined, primaryColor),
              ],
            ).animate().fadeIn().slideY(begin: 0.3, end: 0, delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, Color primaryColor) {
    return GestureDetector(
      onTap: () => _handleSubmitted(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: primaryColor.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isUser,
    DateTime timestamp,
    Color bubbleUser,
    Color bubbleBot,
    Color accentColor,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? bubbleUser : bubbleBot,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
          border: Border.all(
            color: isUser ? accentColor.withOpacity(0.3) : Colors.white10,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.95),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(timestamp),
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTypingIndicator(Color bubbleBot) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bubbleBot,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [0, 1, 2]
              .map(
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      delay: (i * 200).ms,
                      duration: 600.ms,
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                    ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(Color surfaceColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mic button — hold to record
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecordingAndProcess(),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Hold the mic button to record',
                    style: GoogleFonts.outfit(),
                  ),
                  backgroundColor: const Color(0xFF2A2A3C),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.redAccent.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? Colors.redAccent : Colors.white10,
                ),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_rounded,
                color: _isRecording ? Colors.redAccent : Colors.white70,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
