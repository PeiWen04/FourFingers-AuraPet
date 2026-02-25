import 'package:aura_pet/pages/mini_games_page.dart';
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../utils/recommendation_engine.dart';
import 'glass_card.dart';

// Import your pages
import '../pages/sleep_page.dart';
import '../pages/mindfulness_page.dart'; // Assuming you created this

class MoodRecommendationCard extends StatelessWidget {
  final MoodEntry log;

  const MoodRecommendationCard({super.key, required this.log});

  bool get _isNightTime {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 8;
  }

  @override
  Widget build(BuildContext context) {
    final data = RecommendationEngine.analyze(log);
    final isNight = _isNightTime;

    // Dynamic UI based on time of day
    final String btnLabel = isNight ? "Sleep Stories" : "Meditation";
    final IconData btnIcon = isNight ? Icons.book : Icons.self_improvement;
    final List<Color> btnGradient = isNight
        ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)] // Green/Teal
        : [const Color(0xFFF093FB), const Color(0xFFF5576C)]; // Pink/Orange

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  "Personalized For You",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quote Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.format_quote,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                  Text(
                    data['quote'] ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['advice'] ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row
            Row(
              children: [
                // Game Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MiniGamesPage(),
                      ),
                    ),
                    child: _buildGradientButton(
                      label: "Play Game",
                      icon: Icons.sports_esports,
                      colors: [
                        const Color(0xFF4FACFE),
                        const Color(0xFF00F2FE),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Meditation/Sleep Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isNight) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SleepPage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MindfulnessPage(),
                          ),
                        );
                      }
                    },
                    child: _buildGradientButton(
                      label: btnLabel,
                      icon: btnIcon,
                      colors: btnGradient,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the gradient buttons
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
