import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

class FeedbackManagementPage extends StatefulWidget {
  const FeedbackManagementPage({super.key});

  @override
  State<FeedbackManagementPage> createState() => _FeedbackManagementPageState();
}

class _FeedbackManagementPageState extends State<FeedbackManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminService _adminService = AdminService();

  void _updateFeedbackStatus(
    String userId,
    String feedbackId,
    String newStatus,
  ) {
    _firestore
        .collection('User-Module')
        .doc(userId)
        .collection('Feedback')
        .doc(feedbackId)
        .update({'status': newStatus})
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Status updated to $newStatus')),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to update: $error')));
          }
        });
  }

  void _showResolveDialog(
    String userId,
    String feedbackId,
    String feedbackContent,
  ) {
    final titleController = TextEditingController(text: 'Feedback Response');
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve & Notify User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Feedback:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(feedbackContent),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Response Message',
                  border: OutlineInputBorder(),
                  hintText: 'Thank you for your feedback...',
                ),
                maxLines: 5,
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
              if (messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a response message'),
                  ),
                );
                return;
              }

              final success = await _adminService.resolveFeedbackAndNotify(
                userId: userId,
                feedbackId: feedbackId,
                title: titleController.text.trim(),
                message: messageController.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback resolved and user notified'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to resolve feedback'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve & Notify'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFeedback(String userId, String feedbackId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text(
          'Are you sure you want to delete this feedback? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('User-Module')
          .doc(userId)
          .collection('Feedback')
          .doc(feedbackId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Feedback Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('Feedback').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbacks = snapshot.data!.docs;

          int getStatusValue(String status) {
            switch (status) {
              case 'Ongoing':
                return 0;
              case 'Unsolved':
                return 1;
              case 'Resolved':
                return 2;
              default:
                return 3;
            }
          }

          feedbacks.sort((a, b) {
            final statusA = (a.data() as Map<String, dynamic>)['status'] ?? '';
            final statusB = (b.data() as Map<String, dynamic>)['status'] ?? '';
            return getStatusValue(statusA).compareTo(getStatusValue(statusB));
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Reports: ${feedbacks.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const <DataColumn>[
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Reported Date')),
                      DataColumn(label: Text('Feedback')),
                      DataColumn(label: Text('Rating')),
                      DataColumn(label: Text('Evidence')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: feedbacks.map((doc) {
                      final feedback = doc.data() as Map<String, dynamic>;
                      final userId = doc.reference.parent.parent!.id;
                      final feedbackId = doc.id;

                      // Pre-fetch the user document future
                      final userDocFuture = _firestore
                          .collection('User-Module')
                          .doc(userId)
                          .get();

                      return DataRow(
                        cells: <DataCell>[
                          // --- COLUMN: AVATAR ---
                          DataCell(
                            FutureBuilder<DocumentSnapshot>(
                              future: userDocFuture,
                              builder: (context, userSnap) {
                                // Default asset if loading or not found
                                String imagePath = 'assets/penguin.png';

                                if (userSnap.hasData && userSnap.data!.exists) {
                                  final userData =
                                      userSnap.data!.data()
                                          as Map<String, dynamic>;
                                  // Look for 'avatar' field in User-Module
                                  imagePath = userData['avatar'] ?? imagePath;
                                }

                                return CircleAvatar(
                                  backgroundImage: imagePath.startsWith('http')
                                      ? NetworkImage(imagePath) as ImageProvider
                                      : AssetImage(imagePath),
                                );
                              },
                            ),
                          ),
                          // --- COLUMN: NAME ---
                          DataCell(
                            FutureBuilder<DocumentSnapshot>(
                              future: userDocFuture,
                              builder: (context, userSnap) {
                                String name = 'N/A';
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  final userData =
                                      userSnap.data!.data()
                                          as Map<String, dynamic>;
                                  // Look for 'name' field in User-Module
                                  name = userData['username'] ?? 'N/A';
                                }
                                return Text(name);
                              },
                            ),
                          ),
                          DataCell(Text(feedback['reportedDate'] ?? 'N/A')),
                          DataCell(
                            InkWell(
                              onTap: () => _showTextDialog(
                                context,
                                'Full Feedback',
                                feedback['feedbackText'],
                              ),
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  feedback['feedbackText'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < (feedback['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            feedback['attachedImage'] != null
                                ? InkWell(
                                    onTap: () => _showImageDialog(
                                      context,
                                      feedback['attachedImage'],
                                    ),
                                    child: Image.network(
                                      feedback['attachedImage'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Text('No Image'),
                          ),
                          DataCell(
                            _buildStatusChip(feedback['status'] ?? 'Unsolved'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (value) => _updateFeedbackStatus(
                                    userId,
                                    feedbackId,
                                    value,
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'Ongoing',
                                      child: Text('Ongoing'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Resolved',
                                      child: Text('Resolved'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Unsolved',
                                      child: Text('Unsolved'),
                                    ),
                                  ],
                                ),
                                if (feedback['status'] != 'Resolved')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _showResolveDialog(
                                      userId,
                                      feedbackId,
                                      feedback['feedbackText'] ?? '',
                                    ),
                                    tooltip: 'Resolve & Notify',
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _deleteFeedback(userId, feedbackId),
                                  tooltip: 'Delete Feedback',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Helpers ---

  void _showTextDialog(BuildContext context, String title, String? text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(text ?? 'No details provided.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(child: Image.network(imageUrl)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Ongoing':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
