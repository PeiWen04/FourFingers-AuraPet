import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

class TroubleDustbinPage extends StatefulWidget {
  const TroubleDustbinPage({super.key});

  @override
  State<TroubleDustbinPage> createState() => _TroubleDustbinPageState();
}

class _TroubleDustbinPageState extends State<TroubleDustbinPage> {
  final TextEditingController _textController = TextEditingController();
  String _troubleText = '';
  bool _isPaperVisible = true;
  bool _isAnimating = false;
  bool _showingInstructions = false; // Flag to manage instruction state

  // --- Animation and Positioning Constants ---
  final double paperHeight = 200.0;
  final double paperWidth = 300.0;
  final double dustbinHeight = 150.0;
  final double dustbinPadding = 10.0;
  final double paperSizeInBin = 80.0;

  @override
  void initState() {
    super.initState();
    // Automatically show instructions when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  void _showInstructions() {
    setState(() => _showingInstructions = true);
    showDialog(
      context: context,
      barrierDismissible: false, // User must press the button to close
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Let it Go 🗑️"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Type your worries or troubles onto the paper."),
            SizedBox(height: 10),
            Text("2. Press the button to watch it shrink and disappear into the bin."),
            SizedBox(height: 10),
            Text("3. Take a deep breath as your trouble goes away."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showingInstructions = false);
            },
            child: const Text("Let's Start!", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _throwAway() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isAnimating = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isPaperVisible = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _troubleText = '';
          _textController.clear();
          _isPaperVisible = true;
          _isAnimating = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double targetBottomDistance = dustbinPadding + dustbinHeight * 0.4;
    final double distanceFromTop = screenHeight - targetBottomDistance;
    final double targetY = (2 * distanceFromTop / screenHeight) - 1;
    final Alignment paperTargetAlignment = Alignment(0, targetY);
    final double buttonOffsetFromCenter = -paperHeight / 2 - 40;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Trouble Dustbin',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
            tooltip: 'How to use',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg-sleep-day.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Paper and text field
          if (_isPaperVisible)
            AnimatedAlign(
              alignment: _isAnimating ? paperTargetAlignment : Alignment.center,
              duration: const Duration(seconds: 1),
              curve: Curves.easeIn,
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeIn,
                width: _isAnimating ? paperSizeInBin : paperWidth,
                height: _isAnimating ? paperSizeInBin : paperHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/paper.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    enabled: !_isAnimating, // Disable editing while animating
                    decoration: const InputDecoration(
                      hintText: 'Write your troubles here...',
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      setState(() {
                        _troubleText = text;
                      });
                    },
                  ),
                ),
              ),
            ),

          // 3. Dustbin
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: dustbinPadding),
              child: Image.asset(
                'assets/dustbin.png',
                width: dustbinHeight,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.delete, size: 100, color: Colors.grey),
              ),
            ),
          ),

          // 4. Throw Away Button
          if (_troubleText.isNotEmpty &&
              _isPaperVisible &&
              !_isAnimating &&
              !_showingInstructions)
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, buttonOffsetFromCenter),
                child: ElevatedButton.icon(
                  onPressed: _throwAway,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Throw it away!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}