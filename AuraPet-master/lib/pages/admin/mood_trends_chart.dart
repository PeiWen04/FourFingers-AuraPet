import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Useful for date comparisons

// Ensure this map is accessible or redefine it here
Map<String, int> moodScoreMap = {
  'Great': 5,
  'Good': 4,
  'Neutral': 3,
  'Sad': 2,
  'Bad': 1,
};
String _getMoodLabel(double score) {
  if (score == 0) return "No Data";
  if (score >= 4.5) return "Great! 🤩";
  if (score >= 4.0) return "Good 😊";
  if (score >= 3.0) return "Neutral 😐";
  if (score >= 2.0) return "Sad 😓";
  return "Bad 😡";
}

enum ChartView { weekly, monthly, yearly }

class MoodTrendsChart extends StatefulWidget {
  const MoodTrendsChart({super.key});

  @override
  State<MoodTrendsChart> createState() => _MoodTrendsChartState();
}

class _MoodTrendsChartState extends State<MoodTrendsChart> {
  ChartView _selectedView = ChartView.weekly;

  /// Defines the maximum X-axis value based on view
  /// Weekly: 0-6 (7 days), Monthly: 0-29 (30 days), Yearly: 0-11 (12 months)
  int get _maxIndex {
    switch (_selectedView) {
      case ChartView.weekly:
        return 6;
      case ChartView.monthly:
        return 29;
      case ChartView.yearly:
        return 11;
    }
  }

  /// 1. Query Firestore based on the selected view
  Stream<List<FlSpot>> _getMoodDataStream() {
    final now = DateTime.now();
    DateTime startDate;

    // Calculate Start Date
    switch (_selectedView) {
      case ChartView.weekly:
        // Go back 6 days (so total range is 7 days including today)
        startDate = now.subtract(const Duration(days: 6));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ); // Midnight
        break;
      case ChartView.monthly:
        startDate = now.subtract(const Duration(days: 29));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ChartView.yearly:
        // Go back 11 months
        startDate = DateTime(now.year, now.month - 11, 1);
        break;
    }

    return FirebaseFirestore.instance
        .collectionGroup('mood_logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => _processQueryDocs(snapshot.docs, now));
  }

  /// 2. Process the raw documents into Chart Spots (Average per day/month)
  List<FlSpot> _processQueryDocs(
    List<QueryDocumentSnapshot> docs,
    DateTime now,
  ) {
    if (docs.isEmpty) return [];

    // Map to store list of scores for each index.
    // Key = X-axis index, Value = List of scores for that day/month
    Map<int, List<int>> groupedData = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['timestamp'];
      final String? label = data['moodLabel'];

      if (ts == null || label == null) continue;

      final date = ts.toDate();
      final score = moodScoreMap[label] ?? 3;

      int index = -1;

      // Calculate which "Bar" (Index) this log belongs to
      if (_selectedView == ChartView.yearly) {
        // Year logic: Calculate month difference
        // If current is Dec (12), and log is Oct (10), diff is 2. Index = 11 - 2 = 9.
        int monthDiff = (now.year - date.year) * 12 + (now.month - date.month);
        index = 11 - monthDiff;
      } else {
        // Day logic: Calculate day difference
        int dayDiff = now.difference(date).inDays;
        // Adjust for "same day" calculation if hours interfere, strictly strip time
        final dateMidnight = DateTime(date.year, date.month, date.day);
        final nowMidnight = DateTime(now.year, now.month, now.day);
        dayDiff = nowMidnight.difference(dateMidnight).inDays;

        index = _maxIndex - dayDiff;
      }

      // Only add if within valid range
      if (index >= 0 && index <= _maxIndex) {
        groupedData.putIfAbsent(index, () => []).add(score);
      }
    }

    // Calculate Averages and create Spots
    List<FlSpot> spots = [];
    groupedData.forEach((index, scores) {
      double avg = scores.reduce((a, b) => a + b) / scores.length;
      spots.add(FlSpot(index.toDouble(), avg));
    });

    // Sort by X index so the line draws correctly left-to-right
    spots.sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  /// Helper to format date based on index and view
  String _getDateLabel(double value) {
    DateTime now = DateTime.now();

    if (_selectedView == ChartView.weekly) {
      DateTime date = now.subtract(Duration(days: _maxIndex - value.toInt()));
      return "${date.day}/${date.month}";
    } else if (_selectedView == ChartView.monthly) {
      DateTime date = now.subtract(Duration(days: _maxIndex - value.toInt()));
      return "${date.day}/${date.month}";
    } else {
      // Yearly logic
      int monthIndex = (now.month - (11 - value.toInt()));
      // Handle wrapping years (e.g., index -1 becomes Dec of prev year)
      // Easier way: Get the actual date by subtracting months
      DateTime date = DateTime(now.year, now.month - (11 - value.toInt()), 1);
      return DateFormat(
        'MMM',
      ).format(date); // Requires intl package or use manual array
    }
  }

  double _getInterval() {
    switch (_selectedView) {
      case ChartView.weekly:
        return 1;
      case ChartView.monthly:
        return 5;
      case ChartView.yearly:
        return 2;
    }
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
            // --- Header: Title + Dropdown ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "User Mood Trends",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ChartView>(
                      value: _selectedView,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blueAccent,
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (ChartView? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedView = newValue;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ChartView.weekly,
                          child: Text("Weekly"),
                        ),
                        DropdownMenuItem(
                          value: ChartView.monthly,
                          child: Text("Monthly"),
                        ),
                        DropdownMenuItem(
                          value: ChartView.yearly,
                          child: Text("Yearly"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- Chart Area Wrapped in StreamBuilder ---
            SizedBox(
              height: 250,
              child: StreamBuilder<List<FlSpot>>(
                stream: _getMoodDataStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error loading data: ${snapshot.error}"),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final spots = snapshot.data ?? [];

                  // If no data is available
                  if (spots.isEmpty) {
                    return const Center(
                      child: Text(
                        "No mood logs found for this period.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: _maxIndex.toDouble(),
                      minY: 0,
                      maxY: 6,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.blueAccent,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              // 1. Get the Date using your existing helper
                              final dateLabel = _getDateLabel(spot.x);

                              // 2. Get the Score
                              final scoreLabel = spot.y.toStringAsFixed(1);

                              // 3. Get the Mood Label
                              final moodLabel = _getMoodLabel(spot.y);

                              // 4. Return the multi-line tooltip
                              return LineTooltipItem(
                                "$dateLabel\nScore: $scoreLabel\n$moodLabel",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.5, // Adds spacing between lines
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _getInterval(),
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value > _maxIndex) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _getDateLabel(value),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF23b6e6), Color(0xFF02d39a)],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,

                          // --- 🟢 CHANGE HERE: Enable Dots ---
                          dotData: FlDotData(
                            show: true, // Turn this to true
                            getDotPainter: (spot, percent, barData, index) {
                              // Customizes the dot to look like a bullet point
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white, // Inner color
                                strokeWidth: 2,
                                strokeColor: const Color(
                                  0xFF23b6e6,
                                ), // Border color
                              );
                            },
                          ),

                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF23b6e6).withOpacity(0.3),
                                const Color(0xFF02d39a).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
