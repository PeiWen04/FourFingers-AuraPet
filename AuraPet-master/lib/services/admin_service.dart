import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track user activity
  Future<void> trackUserActivity(String userId) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _firestore.collection('User-Module').doc(userId).update({
      'lastActive': FieldValue.serverTimestamp(),
      'activeToday': true,
    });

    // Track session in activity log
    await _firestore
        .collection('User-Module')
        .doc(userId)
        .collection('activity_logs')
        .doc(dateKey)
        .set({
          'date': dateKey,
          'sessions': FieldValue.arrayUnion([Timestamp.now()]),
          'lastActivity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('User-Module').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'username': data['username'] ?? 'Unknown',
          'email': data['email'] ?? 'N/A',
          'avatar': data['avatar'] ?? 'assets/penguin.png',
          'createdAt': data['createdAt'],
          'lastActive': data['lastActive'],
          'activeToday': data['activeToday'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get active users today
  Future<int> getActiveUsersToday() async {
    try {
      final snapshot = await _firestore
          .collection('User-Module')
          .where('activeToday', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active users: $e');
      return 0;
    }
  }

  // Get user activity data for graph
  Future<Map<String, int>> getUserActivityData(String userId, int days) async {
    final Map<String, int> activityData = {};
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      try {
        final doc = await _firestore
            .collection('User-Module')
            .doc(userId)
            .collection('activity_logs')
            .doc(dateKey)
            .get();

        if (doc.exists) {
          final sessions = doc.data()?['sessions'] as List?;
          activityData[dateKey] = sessions?.length ?? 0;
        } else {
          activityData[dateKey] = 0;
        }
      } catch (e) {
        activityData[dateKey] = 0;
      }
    }

    return activityData;
  }

  // Create new user
  Future<Map<String, dynamic>> createNewUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document
      await _firestore.collection('User-Module').doc(userId).set({
        'username': username,
        'email': email,
        'avatar': 'assets/penguin.png',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'activeToday': false,
        'isFirstTime': true,
      });

      return {'success': true, 'uid': userId};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reset username
  Future<bool> resetUsername(String userId, String newUsername) async {
    try {
      await _firestore.collection('User-Module').doc(userId).update({
        'username': newUsername,
      });
      return true;
    } catch (e) {
      print('Error resetting username: $e');
      return false;
    }
  }

  // Reset email
  Future<Map<String, dynamic>> resetEmail(
    String userId,
    String newEmail,
  ) async {
    try {
      // Note: Changing email requires re-authentication in real implementation
      await _firestore.collection('User-Module').doc(userId).update({
        'email': newEmail,
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reset password (admin sends password reset email)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset: $e');
      return false;
    }
  }

  // Resolve feedback and create announcement
  Future<bool> resolveFeedbackAndNotify({
    required String userId,
    required String feedbackId,
    required String title,
    required String message,
  }) async {
    try {
      // Mark feedback as resolved
      await _firestore
          .collection('User-Module')
          .doc(userId)
          .collection('Feedback')
          .doc(feedbackId)
          .update({
            'status': 'Resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
          });

      // Create announcement for user
      await _firestore
          .collection('User-Module')
          .doc(userId)
          .collection('Announcements')
          .add({
            'title': title,
            'message': message,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error resolving feedback: $e');
      return false;
    }
  }

  // Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _firestore
          .collection('User-Module')
          .doc(userId)
          .collection('Announcements')
          .add({
            'title': title,
            'message': message,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Create announcement for all users
  Future<bool> createAnnouncementForAll({
    required String title,
    required String message,
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('User-Module').get();

      for (var userDoc in usersSnapshot.docs) {
        await _firestore
            .collection('User-Module')
            .doc(userDoc.id)
            .collection('Announcements')
            .add({
              'title': title,
              'message': message,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      return true;
    } catch (e) {
      print('Error creating announcement: $e');
      return false;
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore.collection('User-Module').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Reset active today flag (run daily)
  Future<void> resetActiveTodayFlags() async {
    try {
      final snapshot = await _firestore.collection('User-Module').get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'activeToday': false});
      }
    } catch (e) {
      print('Error resetting active flags: $e');
    }
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('User-Module').doc(userId).delete();

      return {'success': true};
    } catch (e) {
      print('Error deleting user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sync user data from Firebase Auth to Firestore
  Future<Map<String, dynamic>> syncUsersFromAuth() async {
    try {
      int updated = 0;
      int skipped = 0;

      // Get all user documents from Firestore
      final firestoreUsers = await _firestore.collection('User-Module').get();

      print('🔄 Starting sync for ${firestoreUsers.docs.length} users...');

      for (var doc in firestoreUsers.docs) {
        final userId = doc.id;
        final currentData = doc.data();

        // Check if email already exists
        if (currentData['email'] != null &&
            currentData['email'] != '' &&
            currentData['createdAt'] != null) {
          print('⏭️ Skipping user $userId - already has email and createdAt');
          skipped++;
          continue;
        }

        try {
          // Note: Firebase Admin SDK would be needed to list all users
          // For now, we'll update based on what's available
          // If the user is currently logged in, we can get their data

          // Check if user has email in auth (this requires the user to be logged in)
          // As a workaround, we'll check if we can update from current auth user
          print('⚠️ User $userId - needs manual sync or admin SDK');
          skipped++;
        } catch (e) {
          print('❌ Error syncing user $userId: $e');
          skipped++;
        }
      }

      print('✅ Sync complete: $updated updated, $skipped skipped');

      return {
        'success': true,
        'updated': updated,
        'skipped': skipped,
        'message':
            'Note: Full sync requires Firebase Admin SDK. Please update emails manually or use cloud function.',
      };
    } catch (e) {
      print('Error syncing users: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update user email and createdAt manually
  Future<Map<String, dynamic>> updateUserEmailAndDate({
    required String userId,
    required String email,
    DateTime? createdAt,
  }) async {
    try {
      final updateData = <String, dynamic>{'email': email};

      if (createdAt != null) {
        updateData['createdAt'] = Timestamp.fromDate(createdAt);
      }

      await _firestore.collection('User-Module').doc(userId).update(updateData);

      print('✅ Updated user $userId with email: $email');
      return {'success': true};
    } catch (e) {
      print('❌ Error updating user $userId: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
