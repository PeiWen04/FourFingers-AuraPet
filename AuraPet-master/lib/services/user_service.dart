import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get username from Firebase Auth or Firestore
  Future<String> getUsername() async {
    final user = _auth.currentUser;
    if (user == null) return 'AuraPet User';

    // First try to get from display name
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // Then try from Firestore
    try {
      final doc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['username'] != null) {
        return doc.data()!['username'];
      }
    } catch (e) {
      print('Error fetching username: $e');
    }

    return 'AuraPet User';
  }

  // Update username in both Firebase Auth and Firestore
  Future<void> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await user.updateDisplayName(newUsername);
    await _firestore.collection('User-Module').doc(user.uid).set({
      'username': newUsername,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Save companion selection
  Future<void> saveCompanionSelection(String petName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final docRef = _firestore.collection('User-Module').doc(user.uid);
    final doc = await docRef.get();

    // Only save if companion hasn't been selected before
    if (!doc.exists || doc.data()?['companion'] == null) {
      await docRef.set({
        'companion': petName,
        'companionSelectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get companion selection
  Future<String?> getCompanionSelection() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data()?['companion'];
      }
    } catch (e) {
      print('Error fetching companion: $e');
    }

    return null;
  }

  // Check if this is first time user (no companion selected)
  Future<bool> isFirstTimeUser() async {
    final companion = await getCompanionSelection();
    return companion == null;
  }

  // Save chat session
  Future<String> saveChatSession({
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final docRef = await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('ChatHistory')
        .add({
          'title': title,
          'messages': messages,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    return docRef.id;
  }

  // Update existing chat session
  Future<void> updateChatSession({
    required String sessionId,
    required List<Map<String, dynamic>> messages,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('ChatHistory')
        .doc(sessionId)
        .update({
          'messages': messages,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Get all chat sessions
  Stream<QuerySnapshot> getChatHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('ChatHistory')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Search chat history
  Future<List<Map<String, dynamic>>> searchChatHistory(String query) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('ChatHistory')
          .get();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final title = data['title']?.toString().toLowerCase() ?? '';
            final messages = data['messages'] as List<dynamic>? ?? [];
            final messageText = messages
                .map((m) => m['text']?.toString().toLowerCase() ?? '')
                .join(' ');

            return title.contains(query.toLowerCase()) ||
                messageText.contains(query.toLowerCase());
          })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error searching chat history: $e');
      return [];
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('ChatHistory')
        .doc(sessionId)
        .delete();
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    if (user.email == null) throw Exception('No email associated with account');

    // Reauthenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
  }

  // Change email
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    if (user.email == null) throw Exception('No email associated with account');

    // Reauthenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Update email
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  // Save avatar selection
  Future<void> saveAvatar(String avatarPath) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('User-Module').doc(user.uid).set({
      'avatar': avatarPath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get avatar selection
  Future<String> getAvatar() async {
    final user = _auth.currentUser;
    if (user == null) return 'assets/penguin.png';

    try {
      final doc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['avatar'] != null) {
        return doc.data()!['avatar'];
      }

      // If no avatar set, check companion selection
      final companion = doc.data()?['companion'];
      if (companion == 'Owl') {
        return 'assets/owl.png';
      }
    } catch (e) {
      print('Error fetching avatar: $e');
    }

    return 'assets/penguin.png';
  }

  // Generate and save daily letter
  Future<String?> generateDailyLetter(String petType) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check if letter already exists for today
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final letterDoc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('DailyLetters')
          .doc(dateKey)
          .get();

      if (letterDoc.exists) {
        return letterDoc.id; // Letter already exists for today
      }

      return dateKey; // Return date key for letter generation
    } catch (e) {
      print('Error checking daily letter: $e');
      return null;
    }
  }

  // Save generated letter content
  Future<void> saveDailyLetterContent({
    required String dateKey,
    required String content,
    required String petType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    print('💌 Saving daily letter: dateKey=$dateKey, petType=$petType');
    print(
      '💌 Letter content preview: ${content.substring(0, content.length > 50 ? 50 : content.length)}...',
    );

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('DailyLetters')
        .doc(dateKey)
        .set({
          'content': content,
          'petType': petType,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

    print('✅ Letter saved successfully to Firebase!');
  }

  // Get unread letters
  Future<List<Map<String, dynamic>>> getUnreadLetters() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Simplified query without orderBy to avoid index requirement
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('DailyLetters')
          .where('isRead', isEqualTo: false)
          .get();

      final letters = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort in memory instead
      letters.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return letters;
    } catch (e) {
      print('Error fetching unread letters: $e');
      // Generate 3 random letters as fallback
      return _generateRandomLetters();
    }
  }

  // Generate random letters as fallback
  List<Map<String, dynamic>> _generateRandomLetters() {
    final today = DateTime.now();
    final letters = <Map<String, dynamic>>[];

    final quotes = [
      '✨ Remember, every small step forward is progress! You\'re doing amazing, and I believe in you wholeheartedly. Keep shining! 🌟',
      '🌈 Today is full of possibilities! Whatever comes your way, know that you have the strength to handle it beautifully. I\'m always here cheering you on! 💙',
      '🦉 Take a moment to breathe and appreciate how far you\'ve come. Your journey is unique and valuable. Be gentle with yourself today. 🍂',
    ];

    for (int i = 0; i < 3; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      letters.add({
        'id': dateKey,
        'content': quotes[i],
        'petType': 'Daily Motivation',
        'isRead': false,
        'createdAt': Timestamp.fromDate(date),
      });
    }

    return letters;
  }

  // Mark letter as read
  Future<void> markLetterAsRead(String dateKey) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('DailyLetters')
        .doc(dateKey)
        .update({'isRead': true});
  }

  // Get today's letter
  Future<Map<String, dynamic>?> getTodayLetter() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in for getTodayLetter');
      return null;
    }

    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    print('📬 Fetching today\'s letter: dateKey=$dateKey, userId=${user.uid}');

    try {
      final letterDoc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('DailyLetters')
          .doc(dateKey)
          .get();

      if (letterDoc.exists) {
        print('✅ Today\'s letter found!');
        return {'id': letterDoc.id, ...letterDoc.data()!};
      } else {
        print('⚠️ No letter found for today');
      }
    } catch (e) {
      print('❌ Error fetching today letter: $e');
    }

    return null;
  }

  // Get all letters (for letter inbox)
  Future<List<Map<String, dynamic>>> getAllLetters() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('DailyLetters')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching all letters: $e');
      return [];
    }
  }

  // Announcement/Notification methods

  // Get all announcements/notifications
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('Announcements')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Get unread announcements count
  Future<int> getUnreadAnnouncementsCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('Announcements')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching unread announcements: $e');
      return 0;
    }
  }

  // Mark announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('Announcements')
        .doc(announcementId)
        .update({'isRead': true});
  }

  // Add notification (for feedback confirmation, etc.)
  Future<void> addNotification({
    required String title,
    required String message,
    String type = 'info', // 'info', 'success', 'feedback'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('Announcements')
        .add({
          'title': title,
          'message': message,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Diary methods

  // Save or update diary for a specific date
  Future<void> saveDiary({
    required String content,
    String? mood,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final diaryDate = date ?? DateTime.now();
    final dateKey =
        '${diaryDate.year}-${diaryDate.month.toString().padLeft(2, '0')}-${diaryDate.day.toString().padLeft(2, '0')}';

    // Check if diary exists for this date
    final docRef = _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('Diary')
        .doc(dateKey);

    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      // Concatenate with existing content
      final existingContent = existingDoc.data()?['content'] ?? '';
      final updatedContent = existingContent.isEmpty
          ? content
          : '$existingContent\n\n---\n\n$content';

      await docRef.update({
        'content': updatedContent,
        'updatedAt': FieldValue.serverTimestamp(),
        if (mood != null) 'mood': mood,
      });
    } else {
      // Create new diary entry
      await docRef.set({
        'content': content,
        'mood': mood,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get diary for a specific date
  Future<Map<String, dynamic>?> getDiary(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final doc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('Diary')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
    } catch (e) {
      print('Error fetching diary: $e');
    }

    return null;
  }

  // Get all diaries
  Future<List<Map<String, dynamic>>> getAllDiaries() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .collection('Diary')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching diaries: $e');
      return [];
    }
  }

  // Save diary to mood_logs for display in mood page
  Future<void> saveDiaryToMoodLogs({
    required String content,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final diaryDate = date ?? DateTime.now();
    final docId =
        '${diaryDate.year}-${diaryDate.month.toString().padLeft(2, '0')}-${diaryDate.day.toString().padLeft(2, '0')}';

    print('📝 Saving diary to mood_logs: docId=$docId, userId=${user.uid}');
    print('📝 Diary content: $content');

    // Check if mood log exists for this date
    final docRef = _firestore
        .collection('User-Module')
        .doc(user.uid)
        .collection('mood_logs')
        .doc(docId);

    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      // Concatenate with existing AI summary
      final existingAISummary = existingDoc.data()?['aiSummary'] ?? '';
      final updatedAISummary = existingAISummary.isEmpty
          ? content
          : '$existingAISummary\n\n---\n\n$content';

      print('📝 Updating existing mood log with aiSummary: $updatedAISummary');
      await docRef.update({'aiSummary': updatedAISummary});
      print('✅ AI summary updated successfully!');
    } else {
      // Create new mood log with just the AI summary
      print('📝 Creating new mood log with aiSummary');
      await docRef.set({
        'timestamp': Timestamp.fromDate(diaryDate),
        'aiSummary': content,
      }, SetOptions(merge: true));
      print('✅ AI summary created successfully!');
    }
  }

  // Check if user has seen the app info dialog
  Future<bool> hasSeenAppInfo() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('User-Module')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data()?['hasSeenAppInfo'] ?? false;
      }
    } catch (e) {
      print('Error checking hasSeenAppInfo: $e');
    }

    return false;
  }

  // Mark app info as seen
  Future<void> markAppInfoAsSeen() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('User-Module').doc(user.uid).set({
        'hasSeenAppInfo': true,
        'appInfoSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking app info as seen: $e');
    }
  }
}
