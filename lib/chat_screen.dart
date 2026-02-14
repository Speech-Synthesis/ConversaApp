import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    Future.delayed(Duration.zero, () {
      // Intentionally empty to show the new "Empty State" UI
    });
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

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addMessage(text, isUser: true);

    setState(() {
      _isTyping = true;
    });

    _scrollToBottom();
    
    // Call Backend API
    try {
      final apiService = ApiService();
      // Use 'kIsWeb' to check platform if needed, or rely on ApiService logic
      // For now, ApiService defaults to localhost (Web)
      
      final response = await apiService.sendMessage(text);
      
      if (mounted) {
        _addMessage(
          response['response'] ?? 'No response from server.',
          isUser: false,
        );
      }
    } catch (e) {
      // Fallback to demo mode so UI is usable without backend
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _addMessage(
            "I'm currently in UI Demo Mode (Backend unreachable).\n\nYour interface looks great!",
            isUser: false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Theme Colors
    final surfaceColor = const Color(0xFF1E1E2E); // Deep distinct blue-black
    final primaryColor = const Color(0xFF6C63FF); // Vibrant violet/purple
    final bubbleUser = primaryColor.withOpacity(0.2);
    final bubbleBot = const Color(0xFF2A2A3C);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent for gradient
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
          // 1. Base Dark Background
          Container(color: surfaceColor),

          // 2. Ambient Gradient Orbs (Mesh Gradient Effect)
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
          
          // 3. Blur Filter for Glassmorphism Smoothness
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 4. Subtle Grid Pattern (Optional, for tech feel)
          /*
          Opacity(
            opacity: 0.03,
            child: Center(
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png', 
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          */
          
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
        ],
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
              "Experience the power of AI conversation",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 14,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0, delay: 100.ms),
            
            const SizedBox(height: 48),
            
            // Suggestion Chips
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
      // decoration: BoxDecoration(
      //   color: surfaceColor,
      //   border: Border(
      //     top: BorderSide(color: Colors.white.withOpacity(0.05)),
      //   ),
      // ),
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
          GestureDetector(
            onTap: () {
              // Placeholder for voice input logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white70, size: 22),
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

