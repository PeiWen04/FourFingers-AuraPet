import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../main.dart';
import 'chat_history_page.dart';
import 'diary_edit_page.dart';
import 'mindfulness_page.dart';
import 'sleep_page.dart';
import 'mini_games_page.dart';
import '../utils/app_settings.dart';
import '../services/pet_brain.dart';
import '../services/user_service.dart';
import 'dart:ui';

class ChatSessionPage extends StatefulWidget {
  final String petName;

  const ChatSessionPage({super.key, required this.petName});

  @override
  State<ChatSessionPage> createState() => _ChatSessionPageState();
}

class _ChatSessionPageState extends State<ChatSessionPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;
  bool _isListening = false;
  String backgroundImage = 'assets/welcome-bg.png';
  final PetService _petService = PetService();
  final UserService _userService = UserService();
  bool _isInitialized = false;
  String? _currentSessionId;

  String _getPetImage() {
    return widget.petName == 'Penguin'
        ? 'assets/penguin.png'
        : 'assets/owl.png';
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializePet();
    _checkFirstTimeUser();
    final petName = widget.petName == 'Penguin' ? 'Poco' : 'Sage';
    _messages.add({
      'text':
          'Now I\'m your pet, $petName! You can chat with me anytime — I\'ll always be here for you.',
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _saveChatToFirestore(); // Save before leaving
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenInfo = prefs.getBool('hasSeenChatInfo') ?? false;

    if (!hasSeenInfo && mounted) {
      // Show info after a short delay to let the page load
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showShortcutsInfo(context, isFirstTime: true);
          prefs.setBool('hasSeenChatInfo', true);
        }
      });
    }
  }

  Future<void> _saveChatToFirestore() async {
    if (_messages.length <= 1) return; // Don't save if only welcome message

    try {
      // Generate concise title using AI
      String title = 'Chat Session';

      // Get first few user messages for context
      final userMessages = _messages
          .where((m) => m['isUser'] == true)
          .take(3)
          .map((m) => m['text'].toString())
          .join('. ');

      if (_isInitialized && userMessages.isNotEmpty) {
        try {
          // Ask AI to generate a short summary title
          final titlePrompt =
              'Create a very short 3-5 word title summarizing this conversation topic: "$userMessages". '
              'Use only topic keywords, NO personal pronouns (I, you, me, my, your). '
              'Example: "Stress management tips" not "How I feel stressed". '
              'Just return the title, nothing else. No quotes.';

          final aiTitle = await _petService.sendMessage(titlePrompt);

          // Clean up the AI response
          title = aiTitle.replaceAll('"', '').replaceAll("'", '').trim();

          // Limit length
          if (title.length > 60) {
            title = '${title.substring(0, 57)}...';
          }

          // Fallback if AI returned something weird
          if (title.isEmpty || title.length < 3) {
            throw Exception('Invalid AI title');
          }
        } catch (e) {
          print('Error generating AI title: $e');
          // Fallback to first user message
          final firstUserMessage = _messages.firstWhere(
            (m) => m['isUser'] == true,
            orElse: () => {'text': 'Chat Session'},
          );

          if (firstUserMessage['text'] != null) {
            title = firstUserMessage['text'].toString().length > 50
                ? '${firstUserMessage['text'].toString().substring(0, 50)}...'
                : firstUserMessage['text'].toString();
          }
        }
      }

      // Convert messages to storable format
      final messagesToStore = _messages
          .map(
            (m) => {
              'text': m['text'],
              'isUser': m['isUser'],
              'timestamp': m['timestamp']?.toIso8601String(),
            },
          )
          .toList();

      if (_currentSessionId == null) {
        // Create new session
        _currentSessionId = await _userService.saveChatSession(
          title: title,
          messages: messagesToStore,
        );
      } else {
        // Update existing session
        await _userService.updateChatSession(
          sessionId: _currentSessionId!,
          messages: messagesToStore,
        );
      }
    } catch (e) {
      print('Error saving chat to Firestore: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializePet() async {
    // Try multiple sources for API key
    var apiKey =
        dotenv.env['GEMINI_API_KEY'] ??
        const String.fromEnvironment('GEMINI_API_KEY') ??
        '';

    print('=== PET INITIALIZATION DEBUG ===');
    print('Running on web: $kIsWeb');
    print('dotenv.env keys: ${dotenv.env.keys.toList()}');
    print(
      'API Key loaded: ${apiKey.isNotEmpty ? 'Yes (${apiKey.length} chars)' : 'No'}',
    );
    if (apiKey.isNotEmpty) {
      print(
        'API Key preview: ${apiKey.substring(0, min(10, apiKey.length))}...',
      );
    }

    if (apiKey.isEmpty) {
      print('✗ ERROR: GEMINI_API_KEY not found!');
      if (kIsWeb) {
        print(
          'For web, run: flutter run -d chrome --dart-define=GEMINI_API_KEY=AIzaSyBISVJ7U_tjvCNfOOURu6-9L7eoL5RcWsA',
        );
      } else {
        print(
          'Make sure .env file exists in project root with GEMINI_API_KEY=your_key',
        );
      }
      return;
    }

    if (apiKey.isNotEmpty) {
      try {
        final petType = widget.petName == 'Penguin'
            ? PetType.penguin
            : PetType.owl;
        print('Initializing pet type: $petType');
        await _petService.initPet(apiKey, petType);
        setState(() {
          _isInitialized = true;
        });
        print('✓ Pet initialized successfully as ${widget.petName}');
      } catch (e) {
        print('✗ Failed to initialize pet: $e');
        print('Error type: ${e.runtimeType}');
      }
    } else {
      print('✗ Please add GEMINI_API_KEY=your_key to .env file');
    }
  }

  void _loadSettings() {
    setState(() {
      backgroundImage = AppSettings.getBackground();
    });
  }

  void _showShortcutsInfo(BuildContext context, {bool isFirstTime = false}) {
    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple.shade50, Colors.teal.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.teal.shade400),
              const SizedBox(height: 16),
              Text(
                isFirstTime ? 'Welcome! 👋' : 'Chat Shortcuts',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildShortcutItem(
                '/activities',
                'Show relaxing activities (Breathing, Meditation, Games, Sleep Stories)',
              ),
              const SizedBox(height: 12),
              _buildShortcutItem(
                '/summary',
                'Generate AI summary of your conversation for your diary',
              ),
              const SizedBox(height: 12),
              _buildShortcutItem(
                '/topic',
                'Get a random conversation starter question',
              ),
              const SizedBox(height: 20),
              Text(
                'Tip: Type / to see command menu',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(isFirstTime ? 'Get Started!' : 'Got it!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem(String command, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              command,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();

    _messageController.clear();

    // Check for commands
    if (userMessage.toLowerCase() == '/activities') {
      setState(() {
        _messages.add({
          'text': 'Here are some activities you might enjoy:',
          'isUser': false,
          'timestamp': DateTime.now(),
          'showActivities': true,
        });
      });
      _scrollToBottom();
      return;
    }

    if (userMessage.toLowerCase() == '/summary') {
      // Generate AI summary from chat messages
      final chatContent = _messages
          .where((m) => !m['isUser'])
          .map((m) => m['text'])
          .join(' ');
      String aiSummary;
      if (_isInitialized && chatContent.isNotEmpty) {
        aiSummary = await _petService.sendMessage(
          'Please create a warm, caring summary of our conversation for the user\'s diary: $chatContent',
        );
      } else {
        aiSummary =
            'Today we had a lovely chat together. You shared your thoughts and feelings, and I was here to listen and support you. 💙';
      }

      setState(() {
        _messages.add({
          'text': 'Here\'s a summary of our conversation:',
          'isUser': false,
          'timestamp': DateTime.now(),
          'showSummary': true,
          'aiSummary': aiSummary,
        });
      });
      _scrollToBottom();
      return;
    }

    if (userMessage.toLowerCase() == '/topic') {
      final questions = [
        'What\'s your favorite way to spend a rainy day?',
        'If you could have dinner with anyone, who would it be?',
        'What\'s something that always makes you smile?',
        'What\'s your dream vacation destination?',
        'What hobby would you love to try?',
      ];
      final randomQuestion =
          questions[(DateTime.now().millisecondsSinceEpoch % questions.length)];
      setState(() {
        _messages.add({
          'text': randomQuestion,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
      return;
    }

    // Get AI response or fallback
    String response;
    if (_isInitialized) {
      print('Sending message to AI: $userMessage');
      response = await _petService.sendMessage(userMessage);
      print('AI response: $response');
    } else {
      print('Using fallback response (AI not initialized)');
      response = "Thanks for sharing! I'm here to listen and support you. 😊";
    }

    if (mounted) {
      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();

      // Save to Firestore after AI response
      _saveChatToFirestore();
    }
  }

  Widget _buildActivityButton(String label, {VoidCallback? onTap}) {
    return OutlinedButton(
      onPressed: onTap ?? () {},
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.teal.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.teal.shade700, fontSize: 10),
      ),
    );
  }

  void _navigateToActivity(String activity) {
    Widget? page;
    switch (activity) {
      case 'Breathing':
        page = const MindfulnessPage();
        break;
      case 'Meditation':
        page = const MindfulnessPage();
        break;
      case 'Game':
        page = const MiniGamesPage();
        break;
      case 'Sleep Story':
        page = const SleepPage();
        break;
    }
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petName == 'Penguin' ? 'Poco' : 'Sage',
          style: TextStyle(fontWeight: FontWeight.bold),),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MyHomePage(title: 'AuraPet', initialIndex: 0),
              ),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showShortcutsInfo(context),
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['isUser'] as bool;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage(_getPetImage()),
                              ),
                            if (!isUser) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.teal.shade400
                                    : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (!isUser &&
                                      (message['text'].toLowerCase().contains(
                                            'sleep story',
                                          ) ||
                                          message['text']
                                              .toLowerCase()
                                              .contains('mini game') ||
                                          message['showActivities'] == true ||
                                          message['showSummary'] == true))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        spacing: 8,
                                        children: [
                                          if (message['text']
                                              .toLowerCase()
                                              .contains('sleep story'))
                                            ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.purple.shade400,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Sleep Stories',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          if (message['text']
                                              .toLowerCase()
                                              .contains('mini game'))
                                            ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange.shade400,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Mini Games',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          if (message['showSummary'] == true)
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => DiaryEditPage(
                                                      summary:
                                                          message['aiSummary'] ??
                                                          'Today we had a lovely chat together. 💙',
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade400,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              child: const Text(
                                                'View',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          if (message['showActivities'] ==
                                              true) ...[
                                            _buildActivityButton(
                                              'Breathing',
                                              onTap: () => _navigateToActivity(
                                                'Breathing',
                                              ),
                                            ),
                                            _buildActivityButton(
                                              'Meditation',
                                              onTap: () => _navigateToActivity(
                                                'Meditation',
                                              ),
                                            ),
                                            _buildActivityButton(
                                              'Game',
                                              onTap: () =>
                                                  _navigateToActivity('Game'),
                                            ),
                                            _buildActivityButton(
                                              'Sleep Story',
                                              onTap: () => _navigateToActivity(
                                                'Sleep Story',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index == 0 && !isUser)
                        Container(
                          margin: const EdgeInsets.only(
                            left: 48,
                            top: 8,
                            bottom: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'I\'ve got some relaxing activities you might enjoy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  _buildActivityButton(
                                    'Breathing',
                                    onTap: () =>
                                        _navigateToActivity('Breathing'),
                                  ),
                                  _buildActivityButton(
                                    'Meditation',
                                    onTap: () =>
                                        _navigateToActivity('Meditation'),
                                  ),
                                  _buildActivityButton(
                                    'Game',
                                    onTap: () => _navigateToActivity('Game'),
                                  ),
                                  _buildActivityButton(
                                    'Sleep Story',
                                    onTap: () =>
                                        _navigateToActivity('Sleep Story'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Mood selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.transparent,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMoodChip('Happy', '😊'),
                    _buildMoodChip('Sad', '😢'),
                    _buildMoodChip('Angry', '😠'),
                    _buildMoodChip('Stressed', '😰'),
                    _buildMoodChip('Tired', '😴'),
                  ],
                ),
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
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
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (text) {
                        if (text == '/') {
                          _showCommandPopup();
                        }
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade400,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(title: 'AuraPet', initialIndex: index),
            ),
            (route) => false,
          );
        },
        selectedItemColor: Colors.teal.shade400,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Companion'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied),
            label: 'Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Mindfulness',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bedtime), label: 'Sleep'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showCommandPopup() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        16,
        MediaQuery.of(context).size.height - 200,
        16,
        100,
      ),
      items: [
        PopupMenuItem(
          value: '/activities',
          child: Row(
            children: [
              const Icon(Icons.sports_esports, size: 20),
              const SizedBox(width: 8),
              const Text('/activities'),
              const SizedBox(width: 8),
              Text(
                'Show activities',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: '/summary',
          child: Row(
            children: [
              const Icon(Icons.summarize, size: 20),
              const SizedBox(width: 8),
              const Text('/summary'),
              const SizedBox(width: 8),
              Text(
                'Summarize chat',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: '/topic',
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 8),
              const Text('/topic'),
              const SizedBox(width: 8),
              Text(
                'Random question',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _messageController.text = value;
      }
    });
  }

  Widget _buildMoodChip(String label, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () {
          _messageController.text = 'I feel $label today';
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.teal.shade50,
          side: BorderSide(color: Colors.teal.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(color: Colors.teal.shade700, fontSize: 14),
        ),
      ),
    );
  }
}
