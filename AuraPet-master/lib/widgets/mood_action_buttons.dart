import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class MoodActionButtons extends StatelessWidget {
  final MoodEntry? selectedLog;
  final VoidCallback onLogTap;
  final VoidCallback onDiaryTap;

  const MoodActionButtons({
    super.key,
    required this.selectedLog,
    required this.onLogTap,
    required this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we have a valid entry for the selected date
    final hasEntry = selectedLog != null && selectedLog!.moodLabel != 'Unknown';

    return Row(
      children: [
        // 1. LOG / EDIT BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onLogTap,
            icon: Icon(hasEntry ? Icons.edit : Icons.add_circle, size: 18),
            label: Text(hasEntry ? "Edit Mood" : "Log Mood"),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasEntry
                  ? selectedLog!.color
                  : Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. DIARY BUTTON
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDiaryTap,
            icon: const Icon(Icons.book, size: 18),
            label: const Text("Diary"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple.shade700,
              side: BorderSide(color: Colors.deepPurple.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
