import 'package:flutter/material.dart';
import 'pet_selection_page.dart';
import '../services/user_service.dart';

class WelcomeSessionPage extends StatefulWidget {
  const WelcomeSessionPage({super.key});

  @override
  State<WelcomeSessionPage> createState() => _WelcomeSessionPageState();
}

class _WelcomeSessionPageState extends State<WelcomeSessionPage>
    with SingleTickerProviderStateMixin {
  bool _showContinueButton = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  String _username = 'UserName';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -0.03,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showContinueButton = true;
        });
      }
    });
  }

  Future<void> _loadUsername() async {
    final username = await _userService.getUsername();
    if (mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/companion-bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Welcome message
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Welcome, $_username!😊',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your journey to calm and happiness begins here — now you can choose your AI pet companion to stay by your side.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Penguin avatar
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value,
                    child: Image.asset(
                      'assets/penguin.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.pets, size: 200);
                      },
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),

              // Continue button
              if (_showContinueButton)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PetSelectionPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Click to continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
