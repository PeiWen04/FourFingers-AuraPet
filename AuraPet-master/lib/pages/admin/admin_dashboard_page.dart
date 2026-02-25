import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/sleep_story.dart';
import '../../services/admin_service.dart';
import 'content_management_page.dart';
import 'user_management_page.dart';
import 'feedback_management_page.dart';
import 'mood_trends_chart.dart';
import 'mood_gauge_today.dart';
import 'announcement_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final List<SleepStory> stories;
  const AdminDashboardPage({super.key, required this.stories});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // AdminService is kept if you need it for other non-stream tasks
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = _buildDashboardPage();
        break;
      case 1:
        page = const UserManagementPage();
        break;
      case 2:
        page = ContentManagementPage();
        break;
      case 3:
        page = const FeedbackManagementPage();
        break;
      case 4:
        page = const AnnouncementManagementPage();
        break;
      default:
        throw UnimplementedError('no widget for $_selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            backgroundColor: const Color(0xFFF0F4FF),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: true,
            leading: const Column(
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '🐧 AuraPet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
              ],
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('User Management'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.content_paste_outlined),
                selectedIcon: Icon(Icons.content_paste),
                label: Text('Content Management'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.feedback_outlined),
                selectedIcon: Icon(Icons.feedback),
                label: Text('Feedback Management'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.announcement_outlined),
                selectedIcon: Icon(Icons.announcement),
                label: Text('Announcements'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: page),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'logout') {
                // Perform logout action
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://cdn-icons-png.flaticon.com/512/9703/9703596.png',
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin', style: TextStyle(color: Colors.black)),
                    Text(
                      'Malaysia',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hi, Admin!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // --- REAL-TIME STATS SECTION ---
            Row(
              children: [
                // 1. Total Users Stream (excluding admin)
                Expanded(
                  child: _buildLiveStatCard(
                    title: "Total Users",
                    // Listens to changes in the 'users' collection, minus 1 for admin
                    stream: _firestore
                        .collection('User-Module')
                        .snapshots()
                        .map((snapshot) {
                          final totalCount = snapshot.docs.length - 1;
                          print(
                            '📊 Total Users (excluding admin): $totalCount',
                          );
                          return totalCount;
                        }),
                  ),
                ),
                const SizedBox(width: 24),

                // 2. Active Users Today Stream
                Expanded(
                  child: _buildLiveStatCard(
                    title: "Active Users Today",
                    stream: _getActiveUsersStream(),
                  ),
                ),
                const SizedBox(width: 24),

                // 3. New Feedbacks Stream (Today's feedback submissions)
                Expanded(
                  child: _buildLiveStatCard(
                    title: "New Feedbacks",
                    stream: _getNewFeedbacksStream(),
                  ),
                ),
              ],
            ),

            // -------------------------------
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: MoodGaugeToday()),
                  const SizedBox(width: 16),
                  Expanded(child: MoodTrendsChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER METHODS FOR LIVE DATA ---

  /// Wraps a StreamBuilder to display live data in a card
  Widget _buildLiveStatCard({
    required String title,
    required Stream<int> stream,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        String displayValue;

        if (snapshot.connectionState == ConnectionState.waiting) {
          displayValue = "..."; // Loading indicator
        } else if (snapshot.hasError) {
          displayValue = "0"; // Show 0 instead of error
          debugPrint("Error loading $title: ${snapshot.error}");
          debugPrint("Stack trace: ${snapshot.stackTrace}");
        } else {
          displayValue = (snapshot.data ?? 0).toString();
        }

        return _buildStatCard(title, displayValue);
      },
    );
  }

  /// Calculates active users based on 'activeToday' field
  Stream<int> _getActiveUsersStream() {
    return _firestore
        .collection('User-Module')
        .where('activeToday', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length - 1;
          print('✅ Active Users Today (excluding admin): $count');
          print(
            '   Active user IDs: ${snapshot.docs.map((doc) => doc.id).toList()}',
          );
          return count;
        });
  }

  /// Gets feedback submitted today (matches current date)
  Stream<int> _getNewFeedbacksStream() {
    return _firestore
        .collectionGroup(
          'Feedback',
        ) // Gets Feedback from User-Module/{userId}/Feedback
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          // Format: "December 31, 2025" (matches Firebase format)
          final months = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          final todayStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

          print('🔍 Looking for today\'s date: $todayStr');

          // Filter by today's date on client side
          final todayFeedbacks = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final reportedDate = data['reportedDate'] as String?;
            return reportedDate == todayStr;
          }).toList();

          print(
            '📝 New Feedbacks (Today - $todayStr): ${todayFeedbacks.length}',
          );
          todayFeedbacks.forEach((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.parent.parent?.id ?? 'unknown';
            print(
              '   - User: $userId | Date: ${data['reportedDate']} | Status: ${data['status']}',
            );
          });
          return todayFeedbacks.length;
        });
  }

  // --- UI WIDGETS ---

  static Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChartPlaceholder(String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(title)),
      ),
    );
  }
}
