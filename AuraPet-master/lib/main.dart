import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/welcome_page.dart';
import 'pages/welcome_session_page.dart';
import 'pages/login_page.dart';
import 'pages/companion_page.dart';
import 'pages/mood_page.dart';
import 'pages/mindfulness_page.dart';
import 'pages/sleep_page.dart';
import 'pages/profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✓ .env file loaded successfully');
  } catch (e) {
    // .env file not found - continue without it
    debugPrint('Note: .env file not found: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraPet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/welcome': (context) => const WelcomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>> _checkUserStatus() async {
    final userService = UserService();
    final isFirstTime = await userService.isFirstTimeUser();
    final avatar = await userService.getAvatar();
    // Check if avatar is set (not default penguin)
    final hasAvatar = avatar != 'assets/penguin.png' || !isFirstTime;
    return {'hasAvatar': hasAvatar, 'isFirstTime': isFirstTime};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _checkUserStatus(),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final data = statusSnapshot.data;
              final hasAvatar = data?['hasAvatar'] ?? false;
              final isFirstTime = data?['isFirstTime'] ?? false;

              // If user has avatar, skip welcome and go to main app
              if (hasAvatar) {
                return const MyHomePage(title: 'AuraPet', initialIndex: 0);
              }

              // First time user without avatar - show welcome session
              if (isFirstTime) {
                return const WelcomeSessionPage();
              }

              // Returning user - show main app
              return const MyHomePage(title: 'AuraPet', initialIndex: 0);
            },
          );
        }

        // User is not logged in - show welcome page
        return const WelcomePage();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.initialIndex = 0,
    this.showFirstTimeInfo = false,
  });

  final String title;
  final int initialIndex;
  final bool showFirstTimeInfo;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _pages => [
    CompanionPage(showFirstTimeInfo: widget.showFirstTimeInfo),
    const MoodPage(),
    const MindfulnessPage(),
    const SleepPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text(widget.title),
      // ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Companion'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied),
            label: 'Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Mindful',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bedtime), label: 'Sleep'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
