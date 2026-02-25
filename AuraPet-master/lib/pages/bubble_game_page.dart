import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';

// Helper class to manage the state of a single bubble
class _BubbleData {
  bool isVisible;
  final double size;
  final bool hasQuote;

  _BubbleData({
    this.isVisible = true,
    required this.size,
    this.hasQuote = false,
  });
}

class BubbleGamePage extends StatefulWidget {
  const BubbleGamePage({super.key});

  @override
  State<BubbleGamePage> createState() => _BubbleGamePageState();
}

class _BubbleGamePageState extends State<BubbleGamePage> {
  late List<List<_BubbleData>> _bubbles;
  final _random = Random();
  String _Avatar = 'assets/penguin-bubble.png';
  final UserService _userService = UserService();

  final List<String> _positiveQuotes = [
    "You are awesome!",
    "Believe in yourself.",
    "You've got this!",
    "Keep shining brightly.",
    "Every day is a fresh start.",
    "You are capable of amazing things.",
    "Your positivity is infectious.",
    "You are stronger than you think.",
  ];

  String _displayedQuote = "";
  bool _isQuoteVisible = false;
  bool _isInfoOpen = false;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _initializeBubbles();
    _loadAvatar();
    // Show instructions automatically on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  final Map<String, String> _AvatarMap = {
    'assets/penguin.png': 'assets/penguin-bubble.png',
    'assets/owl.png': 'assets/owl-bubble.png',
  };

  Future<void> _loadAvatar() async {
    final avatar = await _userService.getAvatar();

    setState(() {
      _Avatar = _AvatarMap[avatar] ?? avatar;
    });
  }

  void _initializeBubbles() {
    setState(() {
      _bubbles = List.generate(6, (_) {
        return List.generate(7, (_) {
          final size = 25.0 + _random.nextDouble() * 20.0;
          final hasQuote = _random.nextInt(7) == 0;
          return _BubbleData(size: size, hasQuote: hasQuote);
        });
      });
    });
  }

  void _showInstructions() {
    setState(() => _isInfoOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Bubble Calm"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• Tap the bubbles to pop them."),
            SizedBox(height: 10),
            Text("• Find hidden bubbles to reveal a positive quote."),
            SizedBox(height: 10),
            Text("• Use this time to breathe and relax."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isInfoOpen = false);
            },
            child: const Text("Let's Start!", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRandomQuote() {
    _quoteTimer?.cancel();
    setState(() {
      _displayedQuote = _positiveQuotes[_random.nextInt(_positiveQuotes.length)];
      _isQuoteVisible = true;
    });
    _quoteTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _isQuoteVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Pop',
          style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: SizedBox(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.deepPurple.shade900.withOpacity(0.5),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Instruction Button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
          // Refresh button to reset the bubbles manually
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializeBubbles,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg-mindfulness.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Game Layout
          SafeArea(
            child: Column(
              children: [
                // Penguin Mascot Area
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      _Avatar,
                      height: 180,
                    ),
                  ),
                ),

                // Scrollable Bubble Grid to prevent overflow
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: List.generate(
                          _bubbles.length,
                              (index) => _buildBubbleRow(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quote Overlay (Floating in center)
          _buildQuoteDisplay(),
        ],
      ),
    );
  }

  Widget _buildBubbleRow(int rowIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_bubbles[rowIndex].length, (colIndex) {
        final bubble = _bubbles[rowIndex][colIndex];
        return GestureDetector(
          onTap: () {
            if (bubble.isVisible) {
              AudioPlayer().play(AssetSource('mindf-bubble-popsound.mp3'));
              setState(() => bubble.isVisible = false);
              if (bubble.hasQuote) _showRandomQuote();
            }
          },
          child: AnimatedOpacity(
            opacity: bubble.isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/icon-mindf-bubble1.png',
                width: bubble.size,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuoteDisplay() {
    return Center(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _isQuoteVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _displayedQuote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}