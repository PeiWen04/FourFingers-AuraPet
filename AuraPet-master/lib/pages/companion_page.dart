import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_session_page.dart';
import 'settings_page.dart';
import '../utils/app_settings.dart';
import '../services/user_service.dart';
import '../services/pet_brain.dart';

class CompanionPage extends StatefulWidget {
  final bool showFirstTimeInfo;

  const CompanionPage({super.key, this.showFirstTimeInfo = false});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  static String? _cachedAvatar;
  String backgroundImage = 'assets/companion-bg.png';
  String petImage = 'assets/penguin.png';
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  bool _hasUnreadLetter = false;
  bool _isGeneratingLetter = false;
  int _unreadAnnouncementsCount = 0;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkUnreadLetters();
    _checkUnreadAnnouncements();

    // Show info dialog for first time users (only once)
    if (widget.showFirstTimeInfo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowFirstTimeInfo();
      });
    }
  }

  Future<void> _checkAndShowFirstTimeInfo() async {
    // Check if user has already seen the app info
    final hasSeenInfo = await _userService.hasSeenAppInfo();
    if (!hasSeenInfo) {
      _showInfoDialog(context);
      // Mark as seen
      await _userService.markAppInfoAsSeen();
    }
  }

  Future<void> _initializePetForLetters() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      try {
        final petType = petImage.contains('penguin')
            ? PetType.penguin
            : PetType.owl;
        await _petService.initPet(apiKey, petType);
      } catch (e) {
        print('Failed to initialize pet for letters: $e');
      }
    }
  }

  void _loadSettings() async {
    // Use cached avatar immediately if available
    if (_cachedAvatar != null) {
      setState(() {
        backgroundImage = AppSettings.getBackground();
        petImage = _cachedAvatar!;
        _isLoadingAvatar = false;
      });
      _initializePetForLetters();
    }

    // Load from Firestore in background
    final avatar = await _userService.getAvatar();
    if (avatar != _cachedAvatar) {
      _cachedAvatar = avatar;
      setState(() {
        petImage = avatar;
        _isLoadingAvatar = false;
      });
      _initializePetForLetters();
    } else if (_cachedAvatar == null) {
      _cachedAvatar = avatar;
      setState(() {
        backgroundImage = AppSettings.getBackground();
        petImage = avatar;
        _isLoadingAvatar = false;
      });
      _initializePetForLetters();
    }
  }

  Future<void> _checkUnreadLetters() async {
    final unreadLetters = await _userService.getUnreadLetters();
    setState(() {
      _hasUnreadLetter = unreadLetters.isNotEmpty;
    });
  }

  Future<void> _checkUnreadAnnouncements() async {
    final count = await _userService.getUnreadAnnouncementsCount();
    setState(() {
      _unreadAnnouncementsCount = count;
    });
  }

  void _showTodayLetter(BuildContext context) async {
    print('🎯 _showTodayLetter called');
    // Get or generate today's letter
    var todayLetter = await _userService.getTodayLetter();

    if (todayLetter == null && !_isGeneratingLetter) {
      print('📝 No letter exists, generating new letter...');
      setState(() {
        _isGeneratingLetter = true;
      });

      // Generate today's letter
      try {
        final petTypeName = petImage.contains('penguin')
            ? 'Poco (Penguin)'
            : 'Sage (Owl)';
        final today = DateTime.now();
        final dateKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        print('🐧 Pet: $petTypeName, Date: $dateKey');

        // Get username for personalization
        final username = await _userService.getUsername();
        print('👤 Username: $username');

        // Hardcoded motivational letters
        final motivationalLetters = [
          '''Dear $username,

✨ I wanted to remind you today that you are doing wonderfully! Every small step you take matters, and I'm so proud of you. Remember to be kind to yourself and take things one moment at a time.

The world is brighter with you in it, and I'm always here by your side, cheering you on! 🌟

With all my love,
$petTypeName 💙''',
          '''Hello beautiful soul! 🌈

Today is a fresh start full of possibilities. Whatever challenges come your way, remember that you have the strength and courage to face them. You've overcome so much already!

Take a deep breath, smile, and know that I believe in you with all my heart. You've got this!

Your forever friend,
$petTypeName 🦋''',
          '''My dear $username,

🌸 Just a gentle reminder that you are enough, exactly as you are. Your journey is unique and beautiful, and every experience is helping you grow.

Be gentle with yourself today. Rest when you need to, celebrate small wins, and remember that I'm always here to listen and support you.

With warmth and care,
$petTypeName 🌺''',
        ];
        final letterIndex = DateTime.now().day % 3;
        final letterContent = motivationalLetters[letterIndex];
        print(
          '📮 Selected letter index: $letterIndex (day ${DateTime.now().day})',
        );
        print(
          '📮 Letter content: ${letterContent.substring(0, letterContent.length > 100 ? 100 : letterContent.length)}...',
        );

        await _userService.saveDailyLetterContent(
          dateKey: dateKey,
          content: letterContent,
          petType: petTypeName,
        );

        print('🔄 Reloading today\'s letter from Firebase...');
        // Reload today's letter
        todayLetter = await _userService.getTodayLetter();

        setState(() {
          _isGeneratingLetter = false;
        });
      } catch (e) {
        print('Error generating daily letter: $e');
        setState(() {
          _isGeneratingLetter = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate letter. Please try again.'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    // Show today's letter content
    if (todayLetter != null) {
      // Mark as read
      await _userService.markLetterAsRead(todayLetter['id']);
      _checkUnreadLetters();

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            height: 450,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/letter-bg.png'),
                fit: BoxFit.none,
                scale: 0.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  todayLetter?['petType'] ?? 'Daily Letter',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        todayLetter?['content'] ?? 'No content',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatSessionPage(
                              petName: petImage.contains('penguin')
                                  ? 'Penguin'
                                  : 'Owl',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Chat Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showLetterDialog(BuildContext context) async {
    // Show all letters in a small dialog
    final letters = await _userService.getAllLetters();

    if (letters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No letters yet. Check back soon!')),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 350,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Letter Inbox',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: letters.length,
                  itemBuilder: (context, index) {
                    final letter = letters[index];
                    final isRead = letter['isRead'] ?? true;

                    return ListTile(
                      leading: Stack(
                        children: [
                          Icon(
                            Icons.mail,
                            color: Colors.teal.shade700,
                            size: 28,
                          ),
                          if (!isRead)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        letter['petType'] ?? 'Daily Letter',
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _formatLetterDate(letter['id']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        // Mark as read
                        if (!isRead) {
                          await _userService.markLetterAsRead(letter['id']);
                          _checkUnreadLetters();
                        }

                        if (!mounted) return;

                        // Show letter content
                        Navigator.pop(context); // Close inbox
                        _showLetterContent(context, letter);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLetterContent(BuildContext context, Map<String, dynamic> letter) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/letter-bg.png'),
              fit: BoxFit.none,
              scale: 0.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                letter['petType'] ?? 'Letter',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatLetterDate(letter['id']),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      letter['content'] ?? 'No content',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLetterDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        if (date == today) {
          return 'Today';
        } else if (date == yesterday) {
          return 'Yesterday';
        } else {
          return DateFormat('MMM d, yyyy').format(date);
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return dateKey;
  }

  void _showLetterInbox(BuildContext context) async {
    // Check if today's letter exists, if not generate it
    final todayLetter = await _userService.getTodayLetter();

    if (todayLetter == null && !_isGeneratingLetter) {
      setState(() {
        _isGeneratingLetter = true;
      });

      // Generate today's letter
      try {
        final petTypeName = petImage.contains('penguin')
            ? 'Poco (Penguin)'
            : 'Sage (Owl)';
        final today = DateTime.now();
        final dateKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Get username for personalization
        final username = await _userService.getUsername();

        // Hardcoded motivational letters
        final motivationalLetters = [
          '''Dear $username,

✨ I wanted to remind you today that you are doing wonderfully! Every small step you take matters, and I'm so proud of you. Remember to be kind to yourself and take things one moment at a time.

The world is brighter with you in it, and I'm always here by your side, cheering you on! 🌟

With all my love,
$petTypeName 💙''',
          '''Hello beautiful soul! 🌈

Today is a fresh start full of possibilities. Whatever challenges come your way, remember that you have the strength and courage to face them. You've overcome so much already!

Take a deep breath, smile, and know that I believe in you with all my heart. You've got this!

Your forever friend,
$petTypeName 🦋''',
          '''My dear $username,

🌸 Just a gentle reminder that you are enough, exactly as you are. Your journey is unique and beautiful, and every experience is helping you grow.

Be gentle with yourself today. Rest when you need to, celebrate small wins, and remember that I'm always here to listen and support you.

With warmth and care,
$petTypeName 🌺''',
        ];
        final letterContent = motivationalLetters[DateTime.now().day % 3];

        await _userService.saveDailyLetterContent(
          dateKey: dateKey,
          content: letterContent,
          petType: petTypeName,
        );

        setState(() {
          _isGeneratingLetter = false;
        });
      } catch (e) {
        print('Error generating daily letter: $e');
        setState(() {
          _isGeneratingLetter = false;
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _LetterInboxDialog(
        petImage: petImage,
        userService: _userService,
        onLetterRead: _checkUnreadLetters,
      ),
    );
  }

  void _showAnnouncements(BuildContext context) async {
    final announcements = await _userService.getAnnouncements();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: announcements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No announcements yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          final isRead = announcement['isRead'] ?? true;
                          final type = announcement['type'] ?? 'info';

                          IconData icon;
                          Color iconColor;

                          switch (type) {
                            case 'success':
                              icon = Icons.check_circle;
                              iconColor = Colors.green;
                              break;
                            case 'feedback':
                              icon = Icons.feedback;
                              iconColor = Colors.blue;
                              break;
                            default:
                              icon = Icons.info;
                              iconColor = Colors.orange;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: iconColor.withOpacity(0.2),
                                    child: Icon(icon, color: iconColor),
                                  ),
                                  if (!isRead)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                announcement['title'] ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                announcement['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                if (!isRead) {
                                  await _userService.markAnnouncementAsRead(
                                    announcement['id'],
                                  );
                                  _checkUnreadAnnouncements();
                                }

                                if (!mounted) return;

                                // Show full announcement
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      announcement['title'] ?? 'Notification',
                                    ),
                                    content: Text(
                                      announcement['message'] ?? '',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.blue.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'App Information',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoItem(
                Icons.mail,
                Colors.blue,
                'Letters',
                'Receive daily motivational letters from your companion pet. Check the mail icon for new letters!',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.notifications,
                Colors.orange,
                'Announcements',
                'Stay updated with app news and notifications. Red dot indicates unread announcements.',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.pets,
                Colors.teal,
                'Pet Characters',
                'Poco (Penguin): Bubbly, optimistic, and cheerful\nSage (Owl): Wise, calming, and thoughtful',
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
                child: const Text('Got it!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNews(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/letter-bg.png'),
              fit: BoxFit.none,
              scale: 0.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'News & Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Feature: Voice Chat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Now you can talk to your pet using voice!',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Update v1.0.1',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bug fixes and performance improvements',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Color.fromARGB(255, 65, 65, 65),
                    size: 28,
                  ),
                  onPressed: () => _showInfoDialog(context),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.mail,
                            color: Color.fromARGB(255, 48, 137, 197),
                            size: 28,
                          ),
                          onPressed: () => _showLetterDialog(context),
                        ),
                        if (_hasUnreadLetter)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Color.fromARGB(255, 233, 198, 3),
                            size: 28,
                          ),
                          onPressed: () => _showAnnouncements(context),
                        ),
                        if (_unreadAnnouncementsCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'I got you a letter! 💌',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoadingAvatar
                      ? const SizedBox(width: 220, height: 220)
                      : Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              petImage,
                              width: petImage == 'assets/owl.png' ? 170 : 220,
                              height: petImage == 'assets/owl.png' ? 170 : 220,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.pets, size: 220);
                              },
                            ),
                            Positioned(
                              bottom: petImage == 'assets/owl.png' ? -28 : 16,
                              child: GestureDetector(
                                onTap: () => _showTodayLetter(context),
                                child: Image.asset(
                                  'assets/letter.png',
                                  width: petImage == 'assets/owl.png'
                                      ? 120
                                      : 140,
                                  height: petImage == 'assets/owl.png'
                                      ? 120
                                      : 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.mail, size: 80);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatSessionPage(
                              petName: petImage == 'assets/penguin.png'
                                  ? 'Penguin'
                                  : 'Owl',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Let's Chat",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterInboxDialog extends StatefulWidget {
  final String petImage;
  final UserService userService;
  final VoidCallback onLetterRead;

  const _LetterInboxDialog({
    required this.petImage,
    required this.userService,
    required this.onLetterRead,
  });

  @override
  State<_LetterInboxDialog> createState() => _LetterInboxDialogState();
}

class _LetterInboxDialogState extends State<_LetterInboxDialog> {
  String? selectedLetterId;
  Map<String, dynamic>? selectedLetter;
  List<Map<String, dynamic>> letters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    final unreadLetters = await widget.userService.getUnreadLetters();
    setState(() {
      letters = unreadLetters;
      isLoading = false;
    });
  }

  Future<void> _openLetter(Map<String, dynamic> letter) async {
    setState(() {
      selectedLetterId = letter['id'];
      selectedLetter = letter;
    });

    // Mark as read
    try {
      await widget.userService.markLetterAsRead(letter['id']);
      widget.onLetterRead();
    } catch (e) {
      print('Error marking letter as read: $e');
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Today';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 400,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/letter-bg.png'),
            fit: BoxFit.none,
            scale: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: selectedLetter == null
            ? Column(
                children: [
                  const Text(
                    'Letter Inbox',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : letters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No new letters yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: letters.length,
                            itemBuilder: (context, index) {
                              final letter = letters[index];
                              final isRead = letter['isRead'] == true;

                              return Card(
                                color: Colors.white.withOpacity(0.9),
                                child: ListTile(
                                  leading: Icon(
                                    isRead ? Icons.mail_outline : Icons.mail,
                                    color: isRead ? Colors.grey : Colors.teal,
                                  ),
                                  title: Text(
                                    letter['petType'] ?? 'Daily Letter',
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatDate(letter['createdAt']),
                                  ),
                                  onTap: () => _openLetter(letter),
                                ),
                              );
                            },
                          ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            selectedLetter = null;
                            selectedLetterId = null;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          selectedLetter!['petType'] ?? 'Daily Letter',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          selectedLetter!['content'] ?? 'No content',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatSessionPage(
                            petName: widget.petImage.contains('penguin')
                                ? 'Penguin'
                                : 'Owl',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start Chat'),
                  ),
                ],
              ),
      ),
    );
  }
}
