import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'audio_player_page.dart';
import '../models/sleep_story.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});
  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  List<SleepStory> _sleepData = [];
  StreamSubscription<QuerySnapshot>? _storiesSubscription;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<dynamic> _suggestions = [];

  // --- RATING FETCHING LOGIC ---

  // Fetches the rating for the current (or test) user from the subcollection
  Future<double> _getTestUserRating(String storyId) async {
    const String testUserId = 'TEST_SLEEP_USER_12345';

    // Determine the user ID dynamically
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? testUserId;

    // If not logged in and not using the test ID, return 0.0
    if (user == null && userId != testUserId) {
      return 0.0;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Sleep-Module')
          .doc(storyId)
          .collection('Ratings')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return (data?['rating'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      print('Error fetching user rating for story $storyId: $e');
    }
    return 0.0;
  }

  // 🛑 FIX: Fetches all stories, updates the 'rating' field to be the user's rating (or fallback), and sorts the list.
  Future<List<SleepStory>> _fetchStoriesWithUserRating(List<SleepStory> stories) async {
    List<SleepStory> storiesWithPersonalizedRating = [];

    // 1. Fetch personalized ratings for each story and create a new list of stories with updated ratings
    for (final story in stories) {
      final userRating = await _getTestUserRating(story.id);

      // If the user has rated this story, use their rating. Otherwise, use the default rating.
      final finalRating = (userRating > 0.0) ? userRating : story.rating;

      storiesWithPersonalizedRating.add(SleepStory(
        id: story.id,
        title: story.title,
        author: story.author,
        description: story.description,
        image: story.image,
        category: story.category,
        audioLink: story.audioLink,
        genre: story.genre,
        rating: finalRating, // THIS IS THE PERSONALIZED RATING USED FOR SORTING
      ));
    }

    // 2. Calculate genre averages based on the NEW personalized ratings.
    final genreRatings = <String, double>{};
    final genreCounts = <String, int>{};

    for (final s in storiesWithPersonalizedRating) { // Use the newly updated list!
      for (final genre in s.genre) {
        genreRatings.update(genre, (value) => value + s.rating, ifAbsent: () => s.rating);
        genreCounts.update(genre, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final genreAverages = <String, double>{};
    for (final genre in genreRatings.keys) {
      genreAverages[genre] = genreRatings[genre]! / genreCounts[genre]!;
    }

    // 3. Sort the stories based on the personalized data.
    storiesWithPersonalizedRating.sort((a, b) {
      final genreAvgsA = a.genre.map((g) => genreAverages[g] ?? 0.0);
      final genreAvgA = genreAvgsA.isNotEmpty ? genreAvgsA.reduce((v, e) => v + e) / genreAvgsA.length : 0.0;

      final genreAvgsB = b.genre.map((g) => genreAverages[g] ?? 0.0);
      final genreAvgB = genreAvgsB.isNotEmpty ? genreAvgsB.reduce((v, e) => v + e) / genreAvgsB.length : 0.0;

      // Primary sort: by the personalized genre average rating (descending).
      final genreCompare = genreAvgB.compareTo(genreAvgA);
      if (genreCompare != 0) {
        return genreCompare;
      }

      // Secondary sort: by the individual story's personalized rating (descending).
      // This ensures that within the same genre, lower-rated stories appear later.
      return b.rating.compareTo(a.rating);
    });

    return storiesWithPersonalizedRating;
  }

  // --- INIT AND DISPOSE ---

  @override
  void initState() {
    super.initState();
    _storiesSubscription = FirebaseFirestore.instance
        .collection('Sleep-Module')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _sleepData = snapshot.docs
          // FILTER FIX: Only process documents that have a 'title' field.
              .where((doc) => (doc.data() as Map<String, dynamic>).containsKey('title'))
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return SleepStory(
              id: doc.id,
              title: data['title'] as String? ?? 'Untitled Story',
              author: data['author'] as String? ?? 'Unknown Author',
              description: data['description'] as String? ?? 'No Description',
              image: data['image'] as String? ?? 'https://defaultimage.com/placeholder.png',
              category: data['category'] as String? ?? 'Misc',
              audioLink: data['audioLink'] as String? ?? '',
              genre: List<String>.from(data['genre'] ?? []),
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
          print('Firestore Data Fetched: ${_sleepData.length} stories loaded.');
        });
      }
    }, onError: (error) {
      print('Error fetching sleep stories: $error');
    });

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
        if (!_isSearchFocused) {
          _suggestions = [];
        }
      });
    });
  }

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- FILTERING AND NAVIGATION ---

  void _onSearchChanged() {
    // ... (Search logic remains the same)
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _suggestions = [];
        return;
      }

      final lowerCaseQuery = query.toLowerCase();

      if (lowerCaseQuery == 'genres' || lowerCaseQuery == 'genre') {
        _suggestions = ['Genres', ..._sleepData.expand((s) => s.genre).toSet()];
        return;
      }
      if (lowerCaseQuery == 'authors' || lowerCaseQuery == 'author') {
        _suggestions = ['Authors', ..._sleepData.map((s) => s.author).toSet()];
        return;
      }
      if (lowerCaseQuery == 'titles' || lowerCaseQuery == 'title') {
        _suggestions = ['Titles', ..._sleepData.map((s) => s.title).toSet()];
        return;
      }

      final titleSuggestions = <String>{};
      final authorSuggestions = <String>{};
      final genreSuggestions = <String>{};

      for (final story in _sleepData) {
        if (story.title.toLowerCase().contains(lowerCaseQuery)) {
          titleSuggestions.add(story.title);
        }
        if (story.author.toLowerCase().contains(lowerCaseQuery)) {
          authorSuggestions.add(story.author);
        }
        if (story.genre.any((g) => g.toLowerCase().contains(lowerCaseQuery))) {
          genreSuggestions.addAll(story.genre.where((g) => g.toLowerCase().contains(lowerCaseQuery)));
        }
      }

      final newSuggestions = <dynamic>[];
      if (genreSuggestions.isNotEmpty) {
        newSuggestions.add('Genres');
        newSuggestions.addAll(genreSuggestions);
      }
      if (authorSuggestions.isNotEmpty) {
        newSuggestions.add('Authors');
        newSuggestions.addAll(authorSuggestions);
      }
      if (titleSuggestions.isNotEmpty) {
        newSuggestions.add('Titles');
        newSuggestions.addAll(titleSuggestions);
      }

      _suggestions = newSuggestions;
    });
  }

  List<SleepStory> getData({String? category}) {
    if (category == null || category == "All") {
      return _sleepData;
    }
    return _sleepData.where((story) => story.category == category).toList();
  }

  void _navigateToPlayer(List<SleepStory> stories, int initialIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioPlayerPage(stories: stories, initialIndex: initialIndex),
      ),
    );
    final currentStory = stories[initialIndex];

    setState(() {}); // Refresh list to trigger the FutureBuilder and update the sort
  }
  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {

    final stories = getData(category: _selectedCategory);

    final filteredStories = stories.where((story) {
      if (_searchQuery.isEmpty) return true;
      final titleMatch = story.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final authorMatch = story.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final genreMatch = story.genre.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()));
      return titleMatch || authorMatch || genreMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sleep Audio",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: SizedBox(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.deepPurple.shade900.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg-sleep-night.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _sleepData.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            :SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Filter Chips and Search Field)
              SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip("All"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Stories"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Soundscapes"),
                    const SizedBox(width: 8),
                    _buildFilterChip("ASMR"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search stories, authors, or genres...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              _buildSuggestions(),
              const SizedBox(height: 24),

              // 🛑 FUTUREBUILDER WRAPPER: Sorts and displays the personalized list
              FutureBuilder<List<SleepStory>>(
                future: _sleepData.isEmpty ? null : _fetchStoriesWithUserRating(filteredStories),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                    if (_sleepData.isNotEmpty) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    return const SizedBox.shrink();
                  }

                  final sortedAndFilteredStories = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedAndFilteredStories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final story = sortedAndFilteredStories[index];
                      return GestureDetector(
                        onTap: () {
                          _navigateToPlayer(sortedAndFilteredStories, index);
                        },
                        // Use the simplified card, as the rating is already updated
                        child: _buildStoryCardSimple(story),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      backgroundColor: Colors.black.withOpacity(0.4),
      selectedColor: Colors.deepPurple.shade300,
      labelStyle: const TextStyle(color: Colors.white),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.deepPurple.shade200),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (!_isSearchFocused || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          if (suggestion is String && ['Genres', 'Authors', 'Titles'].contains(suggestion)) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }
          return ListTile(
            title: Text(suggestion, style: const TextStyle(color: Colors.white)),
            onTap: () {
              _searchController.text = suggestion;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
              _searchFocusNode.unfocus();
            },
          );
        },
      ),
    );
  }

  // 🛑 SIMPLIFIED STORY CARD: Displays the rating already stored in story.rating
  Widget _buildStoryCardSimple(SleepStory story) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Image.network(
                story.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.hide_image, size: 40, color: Colors.white54),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.author,
                      style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            story.genre.join(', '),
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Display the rating which is now the personalized/fallback value
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              story.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}