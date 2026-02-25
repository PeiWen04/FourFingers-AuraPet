import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Mood Scores Map
Map<String, int> moodScoreMap = {
  'Great': 5,
  'Good': 4,
  'Neutral': 3,
  'Sad': 2,
  'Bad': 1,
};

class MoodGaugeToday extends StatelessWidget {
  const MoodGaugeToday({super.key});

  /// Query ALL collections named 'mood_logs' across the entire database
  Stream<QuerySnapshot> _getGlobalMoodStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // ⚠️ CRITICAL CHANGE: Use collectionGroup instead of collection
    return FirebaseFirestore.instance
        .collectionGroup('mood_logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  String _getMoodLabel(double score) {
    if (score == 0) return "No Data";
    if (score >= 4.5) return "Great! 🤩";
    if (score >= 4.0) return "Good 😊";
    if (score >= 3.0) return "Neutral 😐";
    if (score >= 2.0) return "Sad 😓";
    return "Bad 😡";
  }

  Color _getMoodColor(double score) {
    if (score == 0) return Colors.grey;
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Average Mood Today", // Updated Title
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 80),

            // STREAM BUILDER
            StreamBuilder<QuerySnapshot>(
              stream: _getGlobalMoodStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Usually happens if index is missing
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text("Waiting for Index... check console"),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // CALCULATION LOGIC
                double averageScore = 0.0;

                if (docs.isNotEmpty) {
                  double totalScore = 0;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final moodLabel = data['moodLabel'] as String? ?? 'Neutral';
                    totalScore += (moodScoreMap[moodLabel] ?? 3);
                  }
                  averageScore = totalScore / docs.length;
                }

                // Normalize value 0.0 - 1.0
                double progress = 0.0;
                if (averageScore > 0) {
                  progress = (averageScore.clamp(1.0, 5.0) - 1) / 4.0;
                }

                return SizedBox(
                  height: 180,
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(220, 180),
                        painter: GaugePainter(progress),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              averageScore == 0
                                  ? "--"
                                  : averageScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: _getMoodColor(averageScore),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getMoodLabel(averageScore),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Optional: Show how many users contributed
                            Text(
                              "Based on ${docs.length} entries",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. THE PAINTER (Visuals only, no logic changes needed)
// ---------------------------------------------------------

class GaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  GaugePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = min(size.width, size.height) * 0.85;
    const strokeWidth = 20.0;

    // 1. Draw Background Arc (Light Grey)
    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // 2. Draw Gradient Progress Arc
    final gradient = const SweepGradient(
      colors: [Colors.redAccent, Colors.orangeAccent, Colors.greenAccent],
      stops: [0.0, 0.5, 1.0],
      startAngle: pi,
      endAngle: 2 * pi,
    );

    final fgPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * progress, // Sweep based on progress
      false,
      fgPaint,
    );

    // 3. Draw Knob
    final angle = pi + (pi * progress);
    final knobRadius = 12.0;
    final knobCenter = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    final knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Drop shadow
    canvas.drawCircle(
      knobCenter,
      knobRadius + 2,
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Main knob
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);
    // Border
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
