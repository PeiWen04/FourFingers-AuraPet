import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import '../services/user_service.dart';

class MoodTodoList extends StatefulWidget {
  final String userId;
  final String dateId; // Format: "YYYY-MM-DD"

  const MoodTodoList({super.key, required this.userId, required this.dateId});

  @override
  State<MoodTodoList> createState() => _MoodTodoListState();
}

class _MoodTodoListState extends State<MoodTodoList> {
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Firestore Reference helper
  CollectionReference get _tasksRef {
    return FirebaseFirestore.instance
        .collection('User-Module')
        .doc(widget.userId)
        .collection('mood_logs')
        .doc(widget.dateId)
        .collection('tasks');
  }

  Future<void> _addTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    await _tasksRef.add({
      'title': text,
      'isDone': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
    // Keep focus to add multiple tasks quickly
    _focusNode.requestFocus();
  }

  Future<void> _toggleTask(String taskId, bool currentStatus) async {
    // 1. Update Firestore
    await _tasksRef.doc(taskId).update({'isDone': !currentStatus});

    // 2. If we just completed the task (currentStatus was false), show the penguin!
    if (!currentStatus && mounted) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (_, __, ___) => const BouncingPenguinDialog(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
            child: child,
          );
        },
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.deepPurple.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Daily Goals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ],
                ),
                // Optional: Show count
                StreamBuilder<QuerySnapshot>(
                  stream: _tasksRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final total = snapshot.data!.docs.length;
                    final done = snapshot.data!.docs
                        .where((d) => d['isDone'])
                        .length;
                    return Text(
                      "$done/$total",
                      style: TextStyle(
                        color: Colors.deepPurple.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // --- Task List Stream ---
            StreamBuilder<QuerySnapshot>(
              stream: _tasksRef.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 40,
                            color: Colors.deepPurple.shade100,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No goals set for today.",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.deepPurple.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = tasks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isDone = data['isDone'] ?? false;
                    final title = data['title'] ?? '';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteTask(doc.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.deepPurple.withOpacity(0.05)
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDone
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.8),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isDone,
                          activeColor: Colors.deepPurple.shade400,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            title,
                            style: TextStyle(
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.deepPurple.shade200,
                              color: isDone
                                  ? Colors.deepPurple.shade200
                                  : Colors.black87,
                              fontWeight: isDone
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                          onChanged: (_) => _toggleTask(doc.id, isDone),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // --- Add Task Input ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _taskController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Add a new goal...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _addTask,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 🐧 THE BOUNCING PENGUIN DIALOG 🐧 ---

class BouncingPenguinDialog extends StatefulWidget {
  const BouncingPenguinDialog({super.key});

  @override
  State<BouncingPenguinDialog> createState() => _BouncingPenguinDialogState();
}

class _BouncingPenguinDialogState extends State<BouncingPenguinDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  static String? _cachedAvatar;
  String _avatarAsset = 'assets/penguin.png';
  bool _isLoadingAvatar = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Slight wiggle effect
    _rotateAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
          ),
        );

    _controller.forward();

    // Auto-close dialog after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    if (_cachedAvatar != null) {
      setState(() {
        _avatarAsset = _cachedAvatar!;
        _isLoadingAvatar = false;
      });
    }

    final avatar = await _userService.getAvatar();
    if (avatar != _cachedAvatar) {
      _cachedAvatar = avatar;
      setState(() {
        _avatarAsset = avatar;
        _isLoadingAvatar = false;
      });
    } else if (_cachedAvatar == null) {
      _cachedAvatar = avatar;
      setState(() {
        _avatarAsset = avatar;
        _isLoadingAvatar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: child,
                ),
              );
            },
            // ⚠️ IMPORTANT: Replace 'assets/penguin.png' with your actual image
            // If you don't have one, it will show a large emoji instead.
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isLoadingAvatar
                  ? const SizedBox(width: 40, height: 40)
                  : Image.asset(
                _avatarAsset, // <--- REPLACE THIS WITH YOUR IMAGE
                height: 120,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if no image found
                  return const Text("🐧", style: TextStyle(fontSize: 80));
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _controller,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Great Job!",
                style: TextStyle(
                  color: Colors.deepPurple.shade800,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
