class Meditation {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String audioUrl;
  final int duration; // in seconds
  final String category;

  Meditation({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.category,
  });

  factory Meditation.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Meditation(
      id: documentId,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      duration: data['duration'] ?? 0,
      category: data['category'] ?? 'Meditation Music', // Default to music
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'category': category,
    };
  }
}
