import '../models/mood_entry.dart';

class RecommendationEngine {
  static Map<String, String> analyze(MoodEntry log) {
    // 1. Extract Context
    final note = log.note.toLowerCase();
    final moodLabel = log.moodLabel;
    final DateTime now = DateTime.now(); // Or use log.timestamp if available

    // Determine Time of Day
    String timeOfDay;
    if (now.hour < 12) {
      timeOfDay = 'morning';
    } else if (now.hour < 18) {
      timeOfDay = 'afternoon';
    } else {
      timeOfDay = 'evening';
    }

    // Determine General Sentiment (Simplifying mood labels into Positive/Negative/Neutral)
    String sentiment = _getSentimentCategory(moodLabel);

    // 2. Identify Dominant Topic
    String? dominantTopic = _identifyTopic(note);

    // 3. Generate Personalized Output
    return _generateContent(dominantTopic, sentiment, timeOfDay, moodLabel);
  }

  // Helper: Categorize specific mood labels into broad sentiments
  static String _getSentimentCategory(String moodLabel) {
    const positive = ['Great', 'Good', 'Happy', 'Excited'];
    const negative = ['Sad', 'Bad', 'Awful', 'Depressed', 'Angry'];

    if (positive.contains(moodLabel)) return 'positive';
    if (negative.contains(moodLabel)) return 'negative';
    return 'neutral'; // Okay, Meh, Normal
  }

  // Helper: logic to find the topic (Similar to your original code)
  static String? _identifyTopic(String note) {
    final Map<String, List<String>> topics = {
      'Sleep': [
        'tired',
        'sleep',
        'insomnia',
        'awake',
        'exhausted',
        'nap',
        'bed',
        'drained',
      ],
      'Work': [
        'work',
        'job',
        'boss',
        'deadline',
        'meeting',
        'busy',
        'career',
        'email',
      ],
      'School': [
        'exam',
        'study',
        'assignment',
        'grade',
        'class',
        'homework',
        'test',
        'fail',
        'pass',
      ],
      'Social': [
        'friend',
        'party',
        'lonely',
        'family',
        'partner',
        'fight',
        'drama',
        'date',
      ],
      'Anxiety': [
        'anxious',
        'worry',
        'nervous',
        'panic',
        'scared',
        'future',
        'stress',
        'overthinking',
      ],
      'Health': [
        'sick',
        'pain',
        'headache',
        'hurt',
        'doctor',
        'body',
        'gym',
        'workout',
        'diet',
      ],
    };

    String? dominantTopic;
    int maxMatches = 0;

    topics.forEach((topic, keywords) {
      int matches = 0;
      for (var word in keywords) {
        if (note.contains(word)) matches++;
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        dominantTopic = topic;
      }
    });

    return maxMatches > 0 ? dominantTopic : null; // Return null if no matches
  }

  // Helper: The "Brain" that selects the specific string
  static Map<String, String> _generateContent(
    String? topic,
    String sentiment,
    String timeOfDay,
    String rawMood,
  ) {
    String quote = "";
    String advice = "";

    // --- STRATEGY 1: Topic + Sentiment Combination ---
    if (topic != null) {
      if (topic == 'Work') {
        if (sentiment == 'negative') {
          quote = "Your worth is not defined by your productivity.";
          advice = timeOfDay == 'evening'
              ? "Leave the work stress for tomorrow. Tonight is for you."
              : "Burnout is real. Take a 5-minute breather right now.";
        } else {
          quote = "Success is the sum of small efforts repeated.";
          advice = "You're crushing it! Make sure to log this win.";
        }
      } else if (topic == 'Sleep') {
        quote = "Rest is the fuel for success.";
        if (timeOfDay == 'morning') {
          advice =
              "Rough night? Be gentle with yourself today. Hydrate and move slowly.";
        } else {
          advice =
              "Let's wind down. Try putting your phone in another room tonight.";
        }
      } else if (topic == 'Anxiety') {
        quote = "This feeling is a tunnel, not a cave.";
        advice =
            "Try the 5-4-3-2-1 technique: Name 5 things you see, 4 you feel, 3 you hear.";
      } else if (topic == 'Social') {
        if (sentiment == 'negative') {
          quote = "Protect your peace.";
          advice =
              "It is okay to set boundaries. You don't have to fix everything today.";
        } else {
          quote = "Connection is the energy of life.";
          advice =
              "Cherish these moments. Maybe send a quick text to say 'thanks'?";
        }
      } else if (topic == 'School') {
        if (sentiment == 'negative') {
          quote = "Grades measure performance, not intelligence.";
          advice = "Take a step back. One bad day won't ruin your future.";
        } else {
          quote = "Knowledge is power.";
          advice = "Great job on your studies! Reward yourself with a break.";
        }
      }
      // Default fallback for other topics (Health, etc) if not caught above
      else {
        quote = "Listen to your body.";
        advice = "Focus on what you can control right now.";
      }
    }
    // --- STRATEGY 2: Fallback to purely Mood-Based (No Topic Found) ---
    else {
      switch (rawMood) {
        case 'Great':
        case 'Good':
          quote = "Happiness looks good on you.";
          advice = "Keep this momentum going!";
          break;

        case 'Sad':
        case 'Bad':
          quote = "It's okay not to be okay.";
          advice = timeOfDay == 'evening'
              ? "Tomorrow is a fresh start. Get some rest."
              : "Be kind to yourself today. Do one small thing that makes you smile.";
          break;

        case 'Okay':
        default:
          quote = "Balance is key.";
          advice =
              "A neutral day is a perfect canvas. What do you want to add to it?";
          break;
      }
    }

    return {'quote': quote, 'advice': advice};
  }
}
