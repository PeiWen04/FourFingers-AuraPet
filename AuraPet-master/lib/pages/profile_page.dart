import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

// Simple global state for avatar
class AppState {
  static String avatarAsset = "assets/penguin.png";
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static String? _cachedAvatar;
  String _username = "AuraPet User";
  String _avatarPath = "assets/penguin.png";
  bool _isLoadingAvatar = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadAvatar();
  }

  Future<void> _loadUsername() async {
    final username = await _userService.getUsername();
    setState(() {
      _username = username;
    });
  }

  Future<void> _loadAvatar() async {
    if (_cachedAvatar != null) {
      setState(() {
        _avatarPath = _cachedAvatar!;
        _isLoadingAvatar = false;
      });
    }

    final avatar = await _userService.getAvatar();
    if (avatar != _cachedAvatar) {
      _cachedAvatar = avatar;
      setState(() {
        _avatarPath = avatar;
        _isLoadingAvatar = false;
      });
    } else if (_cachedAvatar == null) {
      _cachedAvatar = avatar;
      setState(() {
        _avatarPath = avatar;
        _isLoadingAvatar = false;
      });
    }
  }

  void _changeAvatar() async {
    final selectedAvatar = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Image.asset('assets/penguin.png', width: 50, height: 50),
              title: const Text('Penguin (Poco)'),
              onTap: () => Navigator.of(context).pop('assets/penguin.png'),
            ),
            ListTile(
              leading: Image.asset('assets/owl.png', width: 50, height: 50),
              title: const Text('Owl (Sage)'),
              onTap: () => Navigator.of(context).pop('assets/owl.png'),
            ),
          ],
        ),
      ),
    );

    if (selectedAvatar != null) {
      try {
        await _userService.saveAvatar(selectedAvatar);
        _cachedAvatar = selectedAvatar;
        setState(() {
          _avatarPath = selectedAvatar;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
      }
    }
  }

  void _writeFeedback() {
    showDialog(
      context: context,
      builder: (context) {
        final feedbackController = TextEditingController();
        double rating = 3;
        Uint8List? imageBytes;
        String? imageFileName;

        return AlertDialog(
          title: const Text('Write Feedback'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: feedbackController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your feedback here',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(type: FileType.image, withData: true);
                          if (result != null) {
                            setState(() {
                              imageBytes = result.files.single.bytes;
                              imageFileName = result.files.single.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Image'),
                      ),
                      if (imageFileName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Image selected: $imageFileName',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (feedbackController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your feedback.'),
                    ),
                  );
                  return;
                }

                // Get User ID (Logic handles both logged in and test cases)
                final user = FirebaseAuth.instance.currentUser;
                String finalUserId = user?.uid ?? '1Qp8eh2XcQLH0csHRqgr';

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submitting as TEST USER...')),
                  );
                }

                String? attachedImageUrl;
                if (imageBytes != null && imageFileName != null) {
                  try {
                    final storageRef = FirebaseStorage.instance.ref().child(
                      'feedback_images/${DateTime.now().millisecondsSinceEpoch}_$imageFileName',
                    );
                    final uploadTask = storageRef.putData(
                      imageBytes!,
                      SettableMetadata(contentType: 'image/jpeg'),
                    );
                    final snapshot = await uploadTask.whenComplete(() {});
                    attachedImageUrl = await snapshot.ref.getDownloadURL();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image upload failed: $e')),
                    );
                    return;
                  }
                }

                try {
                  // --- UPDATED FIRESTORE PATH ---
                  // This saves to User-Module/{userId}/Feedback/{auto-generated-id}
                  await FirebaseFirestore.instance
                      .collection('User-Module')
                      .doc(finalUserId)
                      .collection('Feedback')
                      .add({
                        'reportedDate': DateFormat(
                          'MMMM d, yyyy',
                        ).format(DateTime.now()),
                        'feedbackText': feedbackController.text,
                        'rating': rating,
                        'attachedImage': attachedImageUrl,
                        'status': 'Unsolved',
                        'createdAt':
                            FieldValue.serverTimestamp(), // Useful for sorting
                      });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback submitted successfully!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit feedback: $e')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg-mood.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSectionTitle("Account"),
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Edit Username',
              onTap: _editUsername,
            ),
            _buildProfileOption(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: _changePassword,
            ),
            _buildProfileOption(
              icon: Icons.email_outlined,
              title: 'Change Email',
              onTap: _changeEmail,
            ),
            const Divider(height: 32),
            _buildSectionTitle("Feedback"),
            _buildProfileOption(
              icon: Icons.feedback_outlined,
              title: 'Write Report/Feedback',
              onTap: _writeFeedback,
            ),
            const Divider(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _changeAvatar,
          child: _isLoadingAvatar
              ? CircleAvatar(radius: 50, backgroundColor: Colors.grey.shade200)
              : CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(_avatarPath),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _username,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple.shade400),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Log Out',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  void _editUsername() {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new username',
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
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username cannot be empty')),
                );
                return;
              }

              try {
                await _userService.updateUsername(controller.text.trim());
                setState(() {
                  _username = controller.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username updated successfully!'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update username: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
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
                if (currentPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                try {
                  await _userService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to change password';
                  if (e.code == 'wrong-password') {
                    message = 'Current password is incorrect';
                  } else if (e.code == 'weak-password') {
                    message = 'New password is too weak';
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeEmail() {
    final passwordController = TextEditingController();
    final newEmailController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
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
                if (passwordController.text.isEmpty ||
                    newEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                try {
                  await _userService.changeEmail(
                    currentPassword: passwordController.text,
                    newEmail: newEmailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verification email sent! Please check your new email to confirm the change.',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to change email';
                  if (e.code == 'wrong-password') {
                    message = 'Password is incorrect';
                  } else if (e.code == 'email-already-in-use') {
                    message = 'This email is already in use';
                  } else if (e.code == 'invalid-email') {
                    message = 'Invalid email address';
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Change Email'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Navigate to login page
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }
}
