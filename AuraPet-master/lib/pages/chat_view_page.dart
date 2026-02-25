import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';

class ChatViewPage extends StatefulWidget {
  final String chatId;
  final String title;
  final List<dynamic> messages;
  final DateTime dateTime;

  const ChatViewPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.messages,
    required this.dateTime,
  });

  @override
  State<ChatViewPage> createState() => _ChatViewPageState();
}

class _ChatViewPageState extends State<ChatViewPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  String _searchQuery = '';
  List<int> _matchedIndices = [];
  int _currentMatchIndex = -1;
  String _petImage = 'assets/penguin.png';

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final avatar = await _userService.getAvatar();
    setState(() {
      _petImage = avatar;
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _matchedIndices = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <int>[];
    for (int i = 0; i < widget.messages.length; i++) {
      final text = widget.messages[i]['text']?.toString().toLowerCase() ?? '';
      if (text.contains(query.toLowerCase())) {
        matches.add(i);
      }
    }

    setState(() {
      _searchQuery = query;
      _matchedIndices = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (matches.isNotEmpty) {
      _scrollToMatch(0);
    }
  }

  void _scrollToMatch(int matchIndex) {
    if (matchIndex < 0 || matchIndex >= _matchedIndices.length) return;

    final messageIndex = _matchedIndices[matchIndex];
    final itemHeight = 100.0; // Approximate height per message
    final targetPosition = messageIndex * itemHeight;

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _nextMatch() {
    if (_matchedIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchedIndices.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  void _previousMatch() {
    if (_matchedIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchedIndices.length) %
          _matchedIndices.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            Text(
              DateFormat('MMM d, yyyy h:mm a').format(widget.dateTime),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = _searchQuery.isEmpty ? ' ' : '';
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/welcome-bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            if (_searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search in conversation...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _performSearch,
                      ),
                    ),
                    if (_matchedIndices.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_currentMatchIndex + 1}/${_matchedIndices.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: _previousMatch,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: _nextMatch,
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  final isUser = message['isUser'] ?? false;
                  final text = message['text'] ?? '';
                  final timestamp = message['timestamp'] != null
                      ? DateTime.tryParse(message['timestamp'])
                      : null;

                  final isMatched = _matchedIndices.contains(index);
                  final isCurrentMatch =
                      _matchedIndices.isNotEmpty &&
                      _currentMatchIndex >= 0 &&
                      _matchedIndices[_currentMatchIndex] == index;

                  return Container(
                    color: isCurrentMatch
                        ? Colors.yellow.withOpacity(0.3)
                        : isMatched
                        ? Colors.yellow.withOpacity(0.1)
                        : null,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage(_petImage),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.teal.shade400
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                    right: 8,
                                  ),
                                  child: Text(
                                    DateFormat('h:mm a').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.teal.shade400,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a past conversation (read-only)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
