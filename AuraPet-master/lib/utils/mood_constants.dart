import 'package:flutter/material.dart';

// Helper to calculate mood score
int getMoodValue(String label) {
  switch (label) {
    case 'Great':
      return 5;
    case 'Good':
      return 4;
    case 'Okay':
      return 3;
    case 'Sad':
      return 2;
    case 'Bad':
      return 1;
    default:
      return 0;
  }
}

final List<Map<String, dynamic>> moodOptions = [
  {
    'label': 'Great',
    'icon': Icons.sentiment_very_satisfied,
    'color': const Color(0xFF4CAF50), // Green
  },
  {
    'label': 'Good',
    'icon': Icons.sentiment_satisfied,
    'color': const Color(0xFF8BC34A), // Light Green
  },
  {
    'label': 'Okay',
    'icon': Icons.sentiment_neutral,
    'color': const Color(0xFFFFC107), // Amber
  },
  {
    'label': 'Sad',
    'icon': Icons.sentiment_dissatisfied,
    'color': const Color(0xFF2196F3), // Blue
  },
  {
    'label': 'Bad',
    'icon': Icons.sentiment_very_dissatisfied,
    'color': const Color(0xFFF44336), // Red
  },
];
