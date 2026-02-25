/// Mood Scores
/// Happy=5, Neutral=4, Stressed=3, Sad=2, Angry=1
Map<String, int> moodScore = {
  'Happy': 5,
  'Neutral': 4,
  'Stressed': 3,
  'Sad': 2,
  'Angry': 1,
};

/// 7-day mood history (Mon-Sun)
/// Each user has 7 mood scores
final Map<String, List<int>> userMoodHistory = {
  'Adele': [5, 4, 5, 5, 4, 5, 5],
  'Arlene McCoy': [3, 3, 4, 3, 2, 3, 3],
  'Cody Fisher': [2, 3, 3, 2, 3, 3, 2],
  'Esther Howard': [2, 2, 3, 2, 2, 2, 3],
  'Ronald Richards': [3, 4, 3, 4, 3, 4, 4],
};

/// Returns list of 7 values = average score for each day
List<double> getWeeklyAverage() {
  List<double> averages = List.filled(7, 0);

  for (int day = 0; day < 7; day++) {
    int total = 0;
    for (var week in userMoodHistory.values) {
      total += week[day];
    }
    averages[day] = total / userMoodHistory.length;
  }
  return averages;
}

/// Returns today's average mood (0–6 index)
double getTodayAverageMood() {
  int weekdayIndex = DateTime.now().weekday - 1; // Monday = 0
  List<double> weekly = getWeeklyAverage();
  return weekly[weekdayIndex];
}
