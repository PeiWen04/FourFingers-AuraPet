// class SleepStory {
//   final String id;
//   final String title;
//   final String author;
//   final String description;
//   final String image;
//   final String category;
//   final String audioLink;
//   final List<String> genre;
//   double rating;
//
//   SleepStory({
//     required this.id,
//     required this.title,
//     required this.author,
//     required this.description,
//     required this.image,
//     required this.category,
//     required this.audioLink,
//     required this.genre,
//     required this.rating,
//   });
// }

class SleepStory {
  final String id;
  final String title;
  final String author;
  final String description;
  final String image;
  final String category;
  final String audioLink;
  final List<String> genre;
  double rating;

  SleepStory({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.image,
    required this.category,
    required this.audioLink,
    required this.genre,
    required this.rating,
  });

  // --- ADD THIS FACTORY CONSTRUCTOR ---
  factory SleepStory.fromFirestore(Map<String, dynamic> data, String id) {
    return SleepStory(
      id: id,
      title: data['title'] ?? 'Unknown Title',
      author: data['author'] ?? 'Unknown Author',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      category: data['category'] ?? 'Stories',
      audioLink: data['audioLink'] ?? '',
      // Safely handle list conversion
      genre: data['genre'] is List
          ? List<String>.from(data['genre'])
          : [],
      // Safely handle double conversion from Firestore numbers
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }
}
