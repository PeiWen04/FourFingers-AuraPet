import 'package:flutter/material.dart';

class BreathingWidget extends StatefulWidget {
  const BreathingWidget({super.key});

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isRunning = false;
  String _phaseText = "Ready?";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14), // 4s inhale, 4s hold, 6s exhale
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 4),
      TweenSequenceItem(tween: ConstantTween(1.5), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 6),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(begin: const Color(0xffa8e6cf), end: const Color(0xff56ab91)),
          weight: 4),
      TweenSequenceItem(tween: ConstantTween(const Color(0xff56ab91)), weight: 4),
      TweenSequenceItem(
          tween: ColorTween(begin: const Color(0xff56ab91), end: const Color(0xffa8e6cf)),
          weight: 6),
    ]).animate(_controller);

    _controller.addListener(() {
      if (!_isRunning) return;

      final value = _controller.value;
      String newPhase;
      if (value < 4 / 14) {
        newPhase = "Inhale";
      } else if (value < 8 / 14) {
        newPhase = "Hold";
      } else {
        newPhase = "Exhale";
      }
      if (newPhase != _phaseText) {
        setState(() {
          _phaseText = newPhase;
        });
      }
    });
  }

  void _toggleBreathing() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
        _phaseText = "Ready?";
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colorAnimation.value,
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ?? Colors.transparent)
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _phaseText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              blurRadius: 8.0,
                              color: Colors.black38,
                              offset: Offset(2, 2))
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: _toggleBreathing,
            style: ElevatedButton.styleFrom(
              foregroundColor: _isRunning ? Colors.white : const Color(0xff3a6b35),
              backgroundColor:
              _isRunning ? Colors.redAccent.withOpacity(0.8) : Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: Text(
              _isRunning ? "Stop" : "Start",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}