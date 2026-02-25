import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import 'chat_view_page.dart';
import 'dart:ui';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  String _searchQuery = '';
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _allChats = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    _userService.getChatHistory().listen((snapshot) {
      final chats = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final messages = (data['messages'] as List<dynamic>?) ?? [];

        // Get preview from first user message
        String preview = 'No messages';
        if (messages.isNotEmpty) {
          final firstUserMsg = messages.firstWhere(
            (m) => m['isUser'] == true,
            orElse: () => messages.first,
          );
          preview = firstUserMsg['text'] ?? 'No preview';
          if (preview.length > 50) {
            preview = '${preview.substring(0, 50)}...';
          }
        }

        // Parse timestamp
        DateTime dateTime = DateTime.now();
        if (data['updatedAt'] != null) {
          dateTime = (data['updatedAt'] as Timestamp).toDate();
        }

        // Format date string
        String dateStr;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final chatDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

        if (chatDate == today) {
          dateStr = 'Today, ${DateFormat('h:mm a').format(dateTime)}';
        } else if (chatDate == yesterday) {
          dateStr = 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
        } else {
          dateStr = DateFormat('MMM d, yyyy').format(dateTime);
        }

        return {
          'id': doc.id,
          'title': data['title'] ?? 'Chat Session',
          'date': dateStr,
          'preview': preview,
          'dateTime': dateTime,
          'messages': messages,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allChats = chats;
          _isLoading = false;
        });
      }
    });
  }

  void _showCalendarView(BuildContext context) {
    final datesWithChats = _allChats
        .map((chat) => chat['dateTime'] as DateTime)
        .toSet();
    DateTime selectedMonth = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Conversation Dates'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setDialogState(() {
                          selectedMonth = DateTime(
                            selectedMonth.year,
                            selectedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setDialogState(() {
                          selectedMonth = DateTime(
                            selectedMonth.year,
                            selectedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                    itemCount: 42,
                    itemBuilder: (context, index) {
                      if (index < 7) {
                        return Center(
                          child: Text(
                            ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      final firstDayOfMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month,
                        1,
                      );
                      final dayOffset = firstDayOfMonth.weekday % 7;
                      final dayNumber = index - 7 - dayOffset + 1;
                      final daysInMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month + 1,
                        0,
                      ).day;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox();
                      }

                      final date = DateTime(
                        selectedMonth.year,
                        selectedMonth.month,
                        dayNumber,
                      );
                      final hasChat = datesWithChats.any(
                        (chatDate) =>
                            chatDate.year == date.year &&
                            chatDate.month == date.month &&
                            chatDate.day == date.day,
                      );

                      return GestureDetector(
                        onTap: hasChat
                            ? () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: hasChat
                                    ? Colors.teal.shade700
                                    : Colors.black,
                                fontWeight: hasChat
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasChat)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _deleteSelectedChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chats'),
        content: Text(
          'Are you sure you want to delete ${_selectedChatIds.length} chat(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final chatId in _selectedChatIds) {
          await _userService.deleteChatSession(chatId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedChatIds.length} chat(s) deleted')),
        );

        setState(() {
          _isSelectionMode = false;
          _selectedChatIds.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete chats: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    var filtered = _allChats;

    if (_selectedDate != null) {
      filtered = filtered.where((chat) {
        final chatDate = chat['dateTime'] as DateTime;
        return chatDate.year == _selectedDate!.year &&
            chatDate.month == _selectedDate!.month &&
            chatDate.day == _selectedDate!.day;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((chat) {
        return chat['title'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            chat['preview'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedChatIds.length} selected'
              : 'Chat History',
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
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedChatIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
          if (_isSelectionMode && _selectedChatIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedChats,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: Colors.teal.shade700,
                      ),
                      onPressed: () => _showCalendarView(context),
                    ),
                  ],
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            'Filtered: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          backgroundColor: Colors.teal.shade100,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chat history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredHistory[index];
                      return Dismissible(
                        key: Key(chat['id']),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: const Text(
                                'Are you sure you want to delete this chat?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          try {
                            await _userService.deleteChatSession(chat['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat deleted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete chat: $e'),
                              ),
                            );
                          }
                        },
                        child: ListTile(
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: _selectedChatIds.contains(chat['id']),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedChatIds.add(chat['id']);
                                      } else {
                                        _selectedChatIds.remove(chat['id']);
                                      }
                                    });
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: Icon(
                                    Icons.chat,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                          title: Text(
                            chat['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat['preview'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['date'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (_selectedChatIds.contains(chat['id'])) {
                                  _selectedChatIds.remove(chat['id']);
                                } else {
                                  _selectedChatIds.add(chat['id']);
                                }
                              });
                            } else {
                              // Navigate to view chat history
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatViewPage(
                                    chatId: chat['id'],
                                    title: chat['title'],
                                    messages: chat['messages'],
                                    dateTime: chat['dateTime'],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
