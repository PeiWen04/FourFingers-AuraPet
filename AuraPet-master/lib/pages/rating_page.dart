import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart'; // Import to access AppState
import '../services/user_service.dart';

class RatingPage extends StatefulWidget {
  // REQUIREMENT: Must have the ID of the story being rated
  final String storyId;

  const RatingPage({super.key, required this.storyId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _rating = 0;
  String _avatarAsset = 'assets/penguin.png';
  final UserService _userService = UserService();
  bool _isAvatarLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadAvatar();

  }

  Future<void> _loadAvatar() async {
     if (!mounted) return;
     setState(() {
       _isAvatarLoading = true;
     });
     final avatar = await _userService.getAvatar();
     if (!mounted) return;
     setState(() {
       _avatarAsset = avatar;
       _isAvatarLoading = false;
     });
   }

  Future<void> _submitRating(int rating) async {
    // --- Determine User ID ---
    const String testUserId = 'TEST_SLEEP_USER_12345';
    String finalUserId;
    bool isTesting = false;

    final user = _auth.currentUser;
    if (user == null) {
      finalUserId = testUserId;
      isTesting = true;
    } else {
      finalUserId = user.uid;
    }
    // -------------------------

    try {
      // FIX: Write to the nested Ratings subcollection under the specific story document
      await _firestore
          .collection('Sleep-Module')
          .doc(widget.storyId)
          .collection('Ratings')
          .doc(finalUserId) // Uses user ID as document ID for one-rating-per-user
          .set({
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(rating); // Return the rating value
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTesting
                ? 'Rating submitted to TEST ID location.'
                : 'Rating submitted successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
        print('Failed to submit rating: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg-sleep-day.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 7),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Hi, good morning! ❤️\nHow would you rate your overall sleep quality last night?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 100),
            _isAvatarLoading
                ? const SizedBox(
              height: 200,
            )
                : Image.asset(
              _avatarAsset,
              height: 200,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                      _submitRating(_rating);
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
