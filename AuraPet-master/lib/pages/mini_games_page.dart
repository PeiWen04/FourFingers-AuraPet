import 'package:aura_pet/pages/basketball_page.dart';
import 'package:aura_pet/pages/bubble_game_page.dart';
import 'package:flutter/material.dart';
import 'package:aura_pet/pages/color_by_tap_page.dart';
import 'package:aura_pet/pages/trouble_dustbin_page.dart';
import 'dart:ui';

class MiniGamesPage extends StatelessWidget {
  const MiniGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stress-Relief Mini-Games',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg-sleep-day.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameButton(
                context,
                image: 'assets/bubble-game-button.png',
                label: 'Bubble Pop',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BubbleGamePage()),
                ),
              ),
              const SizedBox(height: 30),
              _buildGameButton(
                context,
                image: 'assets/color-game-button.png',
                label: 'Color by Tap',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ColorByTapPage()),
                ),
              ),
              const SizedBox(height: 30),
              _buildGameButton(
                context,
                image: 'assets/dustbin-game-button.png',
                label: 'Trouble Dustbin',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TroubleDustbinPage()),
                ),
              ),
              const SizedBox(height: 30),
              _buildGameButton(
                context,
                image: 'assets/basketball-game-button.png',
                label: 'Basketball Game',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BasketballPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(BuildContext context, {required String image, required String label, required VoidCallback onPressed}) {
    const double imageSize = 100.0;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade600.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}