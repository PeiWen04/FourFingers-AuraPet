import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final DateTime timestamp;
  final String moodLabel;
  final IconData icon;
  final Color color;
  final String note;
  final String aiSummary;

  MoodEntry({
    required this.timestamp,
    required this.moodLabel,
    required this.icon,
    required this.color,
    this.note = '',
    this.aiSummary = '',
  });

  // 🔹 Firestore → MoodEntry
  factory MoodEntry.fromMap(Map<String, dynamic> data) {
    // Handle cases where only diary note exists without mood data
    final iconCodePoint = data['iconCodePoint'] as int?;
    final iconFontFamily = data['iconFontFamily'] as String?;
    final colorValue = data['colorValue'] as int?;

    // Get icon from predefined set to support tree shaking
    IconData iconData = Icons.circle;
    if (iconCodePoint != null) {
      iconData = _getIconFromCodePoint(iconCodePoint);
    }

    return MoodEntry(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      moodLabel: data['moodLabel'] ?? 'Unknown',
      icon: iconData,
      color: colorValue != null ? Color(colorValue) : Colors.grey,
      note: data['note'] ?? '',
      aiSummary: data['aiSummary'] ?? '',
    );
  }

  // Helper method to map code points to constant icons
  static IconData _getIconFromCodePoint(int codePoint) {
    switch (codePoint) {
      case 0xe800: // sentiment_very_satisfied
        return Icons.sentiment_very_satisfied;
      case 0xe801: // sentiment_satisfied
        return Icons.sentiment_satisfied;
      case 0xe802: // sentiment_neutral
        return Icons.sentiment_neutral;
      case 0xe803: // sentiment_dissatisfied
        return Icons.sentiment_dissatisfied;
      case 0xe804: // sentiment_very_dissatisfied
        return Icons.sentiment_very_dissatisfied;
      case 0xeace: // mood
        return Icons.mood;
      case 0xead0: // mood_bad
        return Icons.mood_bad;
      default:
        return Icons.circle;
    }
  }

  // 🔹 MoodEntry → Firestore
  Map<String, dynamic> toJson() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'moodLabel': moodLabel,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'note': note,
      'aiSummary': aiSummary,
    };
  }

  // (unchanged)
  MoodEntry copyWith({
    String? moodLabel,
    IconData? icon,
    Color? color,
    String? note,
    String? aiSummary,
  }) {
    return MoodEntry(
      timestamp: timestamp,
      moodLabel: moodLabel ?? this.moodLabel,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      note: note ?? this.note,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }
}
