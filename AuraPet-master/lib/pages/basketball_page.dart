import 'package:flutter/material.dart';
import 'dart:ui';

void main() => runApp(const MaterialApp(home: BasketballPage()));

class BasketballPage extends StatefulWidget {
  const BasketballPage({super.key});

  @override
  _BasketballPageState createState() => _BasketballPageState();
}

class _BasketballPageState extends State<BasketballPage> with TickerProviderStateMixin {
  // --- Physics Constants ---
  static const double _velocityScale = 0.005;
  static const double _gravity = 0.75;
  static const double _timeStep = 0.16;

  // --- Ball State ---
  double ballX = 0.5;
  double ballY = 0.8;
  double ballSize = 55.0;
  Offset _velocity = Offset.zero;

  // --- Hoop & Backboard State ---
  double basketX = 0.5;
  double basketY = 0.22;
  double basketWidth = 85.0;
  double basketHeight = 10.0;

  double hoopSpeed = 0.004;
  bool movingRight = true;

  int score = 0;
  bool isDragging = false;
  bool _hasScored = false;
  bool _isPaused = false; // Prevents movement during dialogs

  late AnimationController _gameLoop;

  @override
  void initState() {
    super.initState();
    _gameLoop = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();

    // Show instructions automatically on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  void _tick() {
    if (_isPaused) return;
    _updateHoop();
    _updateBall();
  }

  void _updateHoop() {
    setState(() {
      if (movingRight) {
        basketX += hoopSpeed;
        if (basketX > 0.8) movingRight = false;
      } else {
        basketX -= hoopSpeed;
        if (basketX < 0.2) movingRight = true;
      }
    });
  }

  void _updateBall() {
    if (isDragging || _velocity == Offset.zero) return;

    setState(() {
      _velocity = Offset(_velocity.dx, _velocity.dy + _gravity);
      ballX += _velocity.dx * _timeStep * 0.01;
      ballY += _velocity.dy * _timeStep * 0.01;

      _checkCollision();

      if (ballY > 1.1 || ballX < -0.1 || ballX > 1.1) {
        _resetBall();
      }
    });
  }

  void _checkCollision() {
    if (_hasScored) return;

    final contextWidth = MediaQuery.of(context).size.width;
    double hoopLeft = basketX - (basketWidth / 2 / contextWidth);
    double hoopRight = basketX + (basketWidth / 2 / contextWidth);

    if (_velocity.dy > 0 &&
        ballY >= basketY && ballY <= basketY + 0.03 &&
        ballX > hoopLeft && ballX < hoopRight) {
      setState(() {
        score++;
        _hasScored = true;
        if (score % 5 == 0) hoopSpeed += 0.002;
      });
    }
  }

  void _resetBall() {
    _velocity = Offset.zero;
    _hasScored = false;
    ballX = 0.5;
    ballY = 0.8;
  }

  void _showInstructions() {
    setState(() => _isPaused = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("How to Play 🏀"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• Drag the ball to aim."),
            Text("• Flick your finger to shoot."),
            Text("• Score by landing the ball in the hoop."),
            Text("• The hoop speeds up every 5 points!"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isPaused = false);
            },
            child: const Text("Let's Start!"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basketball Game',
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
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hoopXPos = basketX * constraints.maxWidth;
          final hoopYPos = basketY * constraints.maxHeight;

          return Stack(
            children: [
              // 1. Background
              Positioned.fill(
                child: Image.asset(
                  'assets/basketball-court.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.blueGrey[900]),
                ),
              ),

              // 2. Backboard
              Positioned(
                left: hoopXPos - 70,
                top: hoopYPos - 90,
                child: Container(
                  width: 140,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2)),
                    ),
                  ),
                ),
              ),

              // 3. Back Rim
              Positioned(
                left: hoopXPos - basketWidth / 2,
                top: hoopYPos - basketHeight / 2,
                child: Container(
                  width: basketWidth,
                  height: basketHeight,
                  decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // 4. The Ball
              Positioned(
                left: ballX * constraints.maxWidth - ballSize / 2,
                top: ballY * constraints.maxHeight - ballSize / 2,
                child: GestureDetector(
                  onPanStart: (_) => isDragging = true,
                  onPanUpdate: (d) => setState(() {
                    ballX += d.delta.dx / constraints.maxWidth;
                    ballY += d.delta.dy / constraints.maxHeight;
                  }),
                  onPanEnd: (d) {
                    setState(() {
                      isDragging = false;

                      // 1. Get the horizontal and vertical velocity
                      double vx = d.velocity.pixelsPerSecond.dx;
                      double vy = d.velocity.pixelsPerSecond.dy;

                      // 2. Determine if it's a "flick" or a "drop"
                      // We check if the upward velocity is strong enough (negative vy is upward)
                      if (vy.abs() < 200 && vx.abs() < 200) {
                        // User just dropped the ball or dragged it slowly
                        _resetBall();
                      } else {
                        // User flicked the ball
                        _velocity = Offset(
                          vx * _velocityScale,
                          vy * _velocityScale,
                        );
                      }
                    });
                  },
                  child: Image.asset(
                    'assets/basketball.png',
                    width: ballSize,
                    errorBuilder: (c, e, s) => Icon(Icons.sports_basketball, size: ballSize, color: Colors.orange),
                  ),
                ),
              ),

              // 5. Front Net
              Positioned(
                left: hoopXPos - basketWidth / 2,
                top: hoopYPos + basketHeight / 2,
                child: IgnorePointer(
                  child: SizedBox(
                    width: basketWidth,
                    height: 70,
                    child: CustomPaint(painter: NetPainter()),
                  ),
                ),
              ),

              // 6. Score UI
              Positioned(
                top: 10,
                left: 120,
                width: constraints.maxWidth,
                child: Column(
                  children: [
                    Text(
                      'SCORE: $score',
                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (score > 0 && score % 5 == 0)
                      const Text('SPEED UP!', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }
}

class NetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i <= 6; i++) {
      double xTop = (size.width / 6) * i;
      double xBot = (size.width / 10) * i + (size.width * 0.2);
      path.moveTo(xTop, 0);
      path.lineTo(xBot, size.height);
    }
    for (int i = 1; i <= 4; i++) {
      double y = (size.height / 4) * i;
      path.moveTo(0 + (i * 2), y);
      path.lineTo(size.width - (i * 2), y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}