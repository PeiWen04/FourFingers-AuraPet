import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../utils/mood_constants.dart'; // Ensure getMoodValue is here
import 'glass_card.dart';

class WeeklyMoodChart extends StatelessWidget {
  final List<MoodEntry> allLogs;
  final DateTime selectedDate;

  const WeeklyMoodChart({
    super.key,
    required this.allLogs,
    required this.selectedDate,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Logic: Find start and end of the week based on selectedDate
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Normalize time for comparison
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );

    // Filter logs for this specific week
    final weeklyLogs = allLogs
        .where(
          (log) =>
              log.timestamp.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              log.timestamp.isBefore(end),
        )
        .toList();

    // Calculate Average Score
    double totalScore = 0;
    for (var log in weeklyLogs) {
      totalScore += getMoodValue(log.moodLabel);
    }
    final avgScore = weeklyLogs.isEmpty ? 0.0 : totalScore / weeklyLogs.length;

    // Generate data for 7 days
    final weekDays = List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      return weeklyLogs.firstWhere(
        (l) => _isSameDay(l.timestamp, day),
        orElse: () => MoodEntry(
          timestamp: day,
          moodLabel: '',
          icon: Icons.error, // Placeholder, won't be shown
          color: Colors.transparent,
        ),
      );
    });

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Weekly Insight",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${weeklyLogs.length} entries this week",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avgScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // The Bar Chart
            if (weeklyLogs.isNotEmpty)
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weekDays.map((log) {
                    final value = log.moodLabel.isEmpty
                        ? 0
                        : getMoodValue(log.moodLabel);

                    final dayName = [
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ][log.timestamp.weekday - 1];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Container(
                            width: 12,
                            height: (value / 5) * 80, // Scale height
                            decoration: BoxDecoration(
                              color: log.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          )
                        else
                          Container(
                            width: 12,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: value > 0
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              )
            else
              const SizedBox(
                height: 100,
                child: Center(child: Text("No data to show trends")),
              ),
          ],
        ),
      ),
    );
  }
}
