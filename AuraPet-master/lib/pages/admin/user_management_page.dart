import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showAddUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty ||
                  passwordController.text.isEmpty ||
                  usernameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final result = await _adminService.createNewUser(
                email: emailController.text.trim(),
                password: passwordController.text,
                username: usernameController.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${result['error']}')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetUsernameDialog(
    String userId,
    String currentUsername,
  ) async {
    final controller = TextEditingController(text: currentUsername);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _adminService.resetUsername(
                userId,
                controller.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username updated')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update username')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetEmailDialog(String userId, String currentEmail) async {
    final controller = TextEditingController(text: currentEmail);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Note: User will need to log in with new email',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await _adminService.resetEmail(
                userId,
                controller.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Email updated')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${result['error']}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    final success = await _adminService.sendPasswordResetEmail(email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send password reset email')),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _showDeleteUserDialog(String userId, String username) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user "$username"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await _adminService.deleteUser(userId);

              if (!mounted) return;

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSyncEmailDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync User Emails'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will attempt to update user emails and registration dates from Firebase Authentication.',
            ),
            SizedBox(height: 12),
            Text(
              'Note: Full sync requires Firebase Admin SDK. For now, you can manually update emails using the "Edit Email" button for each user.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking user data...')),
              );

              final result = await _adminService.syncUsersFromAuth();

              if (!mounted) return;

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Sync completed'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _showSyncEmailDialog,
            tooltip: 'Sync Emails from Auth',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add New User',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('User-Module').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Error loading users: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;
          print('✅ Loaded ${users.length} users');

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.deepPurple.shade50,
                ),
                columns: const [
                  DataColumn(label: Text('Avatar')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Last Active')),
                  DataColumn(label: Text('Active Today')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = data['username'] ?? '';
                      // Filter out admin users
                      return username.toLowerCase() != 'admin';
                    })
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;

                      // Debug logging
                      print(
                        'User $userId: username=${data['username']}, email=${data['email']}, activeToday=${data['activeToday']}',
                      );

                      return DataRow(
                        cells: [
                          DataCell(
                            CircleAvatar(
                              backgroundImage: AssetImage(
                                data['avatar'] ?? 'assets/penguin.png',
                              ),
                              radius: 20,
                            ),
                          ),
                          DataCell(Text(data['username'] ?? 'N/A')),
                          DataCell(Text(data['email'] ?? 'N/A')),
                          DataCell(Text(_formatTimestamp(data['lastActive']))),
                          DataCell(
                            Icon(
                              (data['activeToday'] ?? false)
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: (data['activeToday'] ?? false)
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showResetUsernameDialog(
                                    userId,
                                    data['username'] ?? '',
                                  ),
                                  tooltip: 'Edit Username',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.email, size: 20),
                                  onPressed: () => _showResetEmailDialog(
                                    userId,
                                    data['email'] ?? '',
                                  ),
                                  tooltip: 'Edit Email',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.lock_reset, size: 20),
                                  onPressed: () =>
                                      _sendPasswordReset(data['email'] ?? ''),
                                  tooltip: 'Reset Password',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _showDeleteUserDialog(
                                    userId,
                                    data['username'] ?? 'Unknown',
                                  ),
                                  tooltip: 'Delete User',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
