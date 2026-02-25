import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:aura_pet/models/meditation.dart';
import 'package:aura_pet/pages/mini_games_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

enum ActiveMode { meditate, breathing }

class MindfulnessPage extends StatefulWidget {
  const MindfulnessPage({super.key});

  @override
  State<MindfulnessPage> createState() => _MindfulnessPageState();
}

class _MindfulnessPageState extends State<MindfulnessPage>
    with TickerProviderStateMixin {
  ActiveMode _activeMode = ActiveMode.meditate;
  bool _isExerciseActive = false;
  bool _isMusicSheetOpen = false;
  bool _isMeditating = false;
  String _selectedDurationFilter = 'All';
  String _petAvatar = 'penguin'; // 'penguin' or 'owl'
  bool _isLoadingAvatar = true;
  static String? _cachedAvatar;
  final UserService _userService = UserService();

  // --- UI Assets & Stats ---
  final double _initialWidth = 50.0;
  final double _selectedWidth = 60.0;
  bool _showStreakMessage = false;

  // --- Breathing Timer & Animation State ---
  late AnimationController _progressController;
  Timer? _breathingTimer;
  int _countdown = 3;
  bool _isCountingDown = true;
  int _currentCycle = 1;
  int _currentPhase = 0;
  bool _isBreathingComplete = false;

  // --- Audio Player State ---
  final AudioPlayer _musicPlayer = AudioPlayer();
  Meditation? _currentItem;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();

    // Animation controller for breathing circle
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initializeAudio();
    _checkFirstSeen();
    _loadAvatar();
  }

  // Load the user's chosen avatar from service
  Future<void> _loadAvatar() async {
    if (_cachedAvatar != null) {
      setState(() {
        _petAvatar = _cachedAvatar!.contains('owl') ? 'owl' : 'penguin';
        _isLoadingAvatar = false;
      });
    }

    final avatar = await _userService.getAvatar();
    if (avatar != _cachedAvatar) {
      _cachedAvatar = avatar;
      setState(() {
        _petAvatar = avatar.contains('owl') ? 'owl' : 'penguin';
        _isLoadingAvatar = false;
      });
    } else if (_cachedAvatar == null) {
      _cachedAvatar = avatar;
      setState(() {
        _petAvatar = avatar.contains('owl') ? 'owl' : 'penguin';
        _isLoadingAvatar = false;
      });
    }
  }

  // Show onboarding dialog if first time launching the page
  void _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('seen_onboarding') ?? false);

    if (!seen) {
      await prefs.setBool('seen_onboarding', true);
      if (mounted) {
        // Wait for the first frame to be drawn before showing a dialog
        WidgetsBinding.instance.addPostFrameCallback((_) => _showOnboarding());
      }
    }
  }

  //Display the onboarding guide dialog
  void _showOnboarding() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: AlertDialog(
          backgroundColor: const Color(0xFFF2EFE8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Column(
            children: [
              _isLoadingAvatar
                  ? const SizedBox(width: 80, height: 80)
                  : Image.asset('assets/icon-mindf-$_petAvatar.png'),
              const SizedBox(height: 10),
              const Text(
                "Mindfulness Guide",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideRow(
                Icons.air,
                "Breathe",
                "Ground yourself with timed exercises.",
              ),
              const SizedBox(height: 15),
              _buildGuideRow(
                Icons.music_note,
                "Music & Meditation",
                "Listen to curated tracks and tutorials.",
              ),
              const SizedBox(height: 15),
              _buildGuideRow(
                Icons.videogame_asset,
                "Games",
                "De-stress with interactive activities.",
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Let's Start!",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Build individual onboarding rows
  Widget _buildGuideRow(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _quitBreathingExercise() {
    _breathingTimer?.cancel();
    _progressController.stop();
    _progressController.reset();

    setState(() {
      _isExerciseActive = false;
      _isCountingDown = true;
      _countdown = 3;
      _currentCycle = 1;
      _currentPhase = 0;
      _isBreathingComplete = false;
    });
  }

  // Starts the box breathing timer and handles phases/cycles
  void _startBreathingLogic() {
    _breathingTimer?.cancel();
    _progressController.stop();
    _progressController.reset();

    setState(() {
      _isCountingDown = true;
      _countdown = 3;
      _isBreathingComplete = false;
      _currentCycle = 1;
      _currentPhase = 0;
    });

    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCountingDown) {
        if (_countdown > 1) {
          setState(() => _countdown--);
        } else {
          setState(() {
            _isCountingDown = false;
            _progressController.forward();
          });
        }
      } else if (!_isBreathingComplete) {
        if (_progressController.isCompleted) {
          setState(() {
            if (_currentPhase < 3) {
              _currentPhase++;
              _progressController.reset();
              _progressController.forward();
            } else {
              if (_currentCycle < 4) {
                _currentCycle++;
                _currentPhase = 0;
                _progressController.reset();
                _progressController.forward();
              } else {
                _isBreathingComplete = true;
                _progressController.stop();
                _breathingTimer?.cancel();
              }
            }
          });
        }
      }
    });
  }

  void _initializeAudio() {
    _stateSub = _musicPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
        _isMeditating = (state == PlayerState.playing);
      });

      if (state == PlayerState.completed) {
        setState(() => _showStreakMessage = true);
        Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showStreakMessage = false);
        });
      }
    });

    // Listen for duration changes and update state
    _durationSub = _musicPlayer.onDurationChanged.listen((d) {
      if (mounted && d.inSeconds > 0) {
        setState(() {
          _duration = d;
        });
      }
    });

    _positionSub = _musicPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });
  }

  // Format duration for display in MM:SS
  String _formatDuration(Duration d) {
    // Use inMinutes
    final String minutes = d.inMinutes.toString().padLeft(2, '0');
    final String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // --- Music Options with 2 Sections and Duration Filtering ---
  void _showMusicOptions() {
    setState(() => _isMusicSheetOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DefaultTabController(
        length: 2,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF2EFE8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                TabBar(
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.deepPurple,
                  tabs: const [
                    Tab(text: "Meditation Tutorial"),
                    Tab(text: "Meditation Music"),
                  ],
                ),
                _buildFilterChips(setSheetState),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMeditationStream('Meditation Tutorial'),
                      _buildMeditationStream('Meditation Music'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() => _isMusicSheetOpen = false);
    });
  }

  //Firestore Stream Handling for Meditation List
  Widget _buildMeditationStream(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meditations')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final items = snapshot.data!.docs
            .map(
              (doc) => Meditation.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Filter based on the selected ChoiceChip
        final filteredItems = _getFilteredItems(items);

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              "No $category found for this duration",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return _buildMeditationGrid(filteredItems);
      },
    );
  }

  // Filter meditation items by duration selection
  List<Meditation> _getFilteredItems(List<Meditation> items) {
    List<Meditation> filtered;
    if (_selectedDurationFilter == 'All') {
      filtered = items;
    } else {
      filtered = items.where((item) {
        final double mins = item.duration.toDouble();

        if (_selectedDurationFilter == '0-10 min') {
          return mins <= 10;
        }
        if (_selectedDurationFilter == '11-30 min') {
          return mins > 10 && mins <= 30;
        }
        if (_selectedDurationFilter == '31-60 min') {
          return mins > 30;
        }
        return true;
      }).toList();
    }

    // Sort by duration so shorter ones appear first within the bracket
    filtered.sort((a, b) => a.duration.compareTo(b.duration));

    return filtered;
  }

  // Build filter ChoiceChips for durations
  Widget _buildFilterChips(Function setSheetState) {
    // Update these strings to match the logic above
    final filters = ['All', '0-10 min', '11-30 min', '31-60 min'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      color: _selectedDurationFilter == f
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: _selectedDurationFilter == f
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  selected: _selectedDurationFilter == f,
                  selectedColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _selectedDurationFilter == f
                          ? Colors.deepPurple
                          : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (val) {
                    setSheetState(() => _selectedDurationFilter = f);
                    setState(() => _selectedDurationFilter = f);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Build grid of meditation card
  Widget _buildMeditationGrid(List<Meditation> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridItem(items[index]),
    );
  }

  // Build individual meditation card
  Widget _buildGridItem(Meditation item) {
    return InkWell(
      onTap: () {
        _playMusic(item);
        Navigator.pop(context);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.imageUrl, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black54,
                      child: Text(
                        "${item.duration}m",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  Text(
                    item.artist,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Music Player Widget
  Widget _buildMusicPlayer() {
    if (_currentItem == null ||
        _playerState == PlayerState.completed ||
        _activeMode == ActiveMode.breathing) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentItem!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        _currentItem!.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _seekRelative(const Duration(seconds: -10)),
                ),
                IconButton(
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () => _playerState == PlayerState.playing
                      ? _musicPlayer.pause()
                      : _musicPlayer.resume(),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _seekRelative(const Duration(seconds: 10)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                // 1. Use .clamp to ensure the thumb never goes outside the track
                value: _position.inSeconds.toDouble().clamp(
                  0.0,
                  _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                ),
                // 2. Ensure max is the full duration
                max: _duration.inSeconds.toDouble() > 0
                    ? _duration.inSeconds.toDouble()
                    : 1.0,
                onChanged: (v) {
                  _musicPlayer.seek(Duration(seconds: v.toInt()));
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seek audio by relative offset
  void _seekRelative(Duration offset) {
    final newPosition = _position + offset;
    if (newPosition < Duration.zero) {
      _musicPlayer.seek(Duration.zero);
    } else if (newPosition > _duration) {
      _musicPlayer.seek(_duration);
    } else {
      _musicPlayer.seek(newPosition);
    }
  }

  // Play meditation music
  void _playMusic(Meditation item) async {
    setState(() => _currentItem = item);
    await _musicPlayer.play(UrlSource(item.audioUrl));
  }

  // Drag handle for bottom sheet
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mindfulness & Games",
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg-mindfulness.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          _buildMainContent(),

          // build method
          if (_activeMode != ActiveMode.breathing) // Only show if NOT breathing
            Positioned(
              top: 20,
              left: 15,
              child: CircleAvatar(
                backgroundColor: const Color(0xFFB18EDE),
                child: IconButton(
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _showOnboarding,
                ),
              ),
            ),

          if (_activeMode != ActiveMode.breathing) ...[
            _buildControlIcons(),
            _buildStreakUI(),
          ],
          _buildMusicPlayer(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_activeMode == ActiveMode.breathing) {
      return _isExerciseActive
          ? _buildActiveBreathingScreen()
          : _buildBreathingStartScreen();
    }
    if (_isLoadingAvatar) {
      return const Align(
        alignment: Alignment(0, 0.7),
        child: SizedBox(width: 250, height: 250),
      );
    }
    String pImg = _isMeditating
        ? 'assets/icon-mindf-$_petAvatar-meditate.png'
        : 'assets/icon-mindf-$_petAvatar.png';
    return Align(
      alignment: const Alignment(0, 0.7),
      child: Image.asset(pImg, height: 250),
    );
  }

  Widget _buildControlIcons() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          right: 30,
          child: _buildLabeledIcon(
            null,
            'assets/icon-mindf-music.png',
            "Music",
            onTap: _showMusicOptions,
            customWidth: 80,
          ),
        ),
        Positioned(
          bottom: 55,
          left: 35,
          child: GestureDetector(
            onTap: () {
              _musicPlayer.pause();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const MiniGamesPage()),
              );
            },
            child: Transform.rotate(
              angle: 0.25,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/game.png', width: 100),
                  Transform.translate(
                    offset: const Offset(0, -13),
                    child: _aestheticLabel("Games"),
                  ),
                ],
              ),
            ),
          ),
        ),

        Align(
          // Adjust these values to find the "sweet spot"
          alignment: const Alignment(-0.2, -0.15),
          child: _buildLabeledIcon(
            ActiveMode.breathing,
            'assets/leaf.png',
            "Breathe",
            customWidth: 80,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledIcon(
    ActiveMode? mode,
    String path,
    String label, {
    VoidCallback? onTap,
    double? customWidth,
  }) {
    bool isSel = mode != null && _activeMode == mode;
    double finalWidth = customWidth ?? (isSel ? _selectedWidth : _initialWidth);

    return GestureDetector(
      onTap:
          onTap ??
          () {
            setState(() {
              _activeMode = mode!;
              _isExerciseActive = false;
            });
            if (mode == ActiveMode.breathing) _musicPlayer.pause();
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: finalWidth,
            child: Image.asset(path),
          ),
          const SizedBox(height: 4),
          _aestheticLabel(label),
        ],
      ),
    );
  }

  Widget _aestheticLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStreakUI() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _showStreakMessage ? 1.0 : 0.0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Congrats, you have done meditation! 🌱",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingStartScreen() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          colors: [Colors.blue.shade300, Colors.blue.shade200, Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () =>
                  setState(() => _activeMode = ActiveMode.meditate),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "1 min Breathing",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Just 60 seconds to calm your thoughts\nand stay grounded.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 50),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.7,
                      child: Image.asset('assets/cloud.png', width: 320),
                    ),
                    _isLoadingAvatar
                        ? const SizedBox(width: 180, height: 180)
                        : Image.asset(
                            'assets/icon-mindf-$_petAvatar.png',
                            height: 180,
                          ),
                  ],
                ),
                const SizedBox(height: 60),
                const Text(
                  "Box breathing",
                  style: TextStyle(
                    color: Color(0xFF455A64),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 280,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _isExerciseActive = true);
                      _startBreathingLogic();
                    },
                    child: const Text(
                      "Begin",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _activeMode = ActiveMode.meditate),
                  child: const Text("Back"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBreathingScreen() {
    String phaseText = _isCountingDown
        ? "..."
        : (_isBreathingComplete
              ? "Well Done!"
              : ["Inhale", "Hold", "Exhale", "Hold"][_currentPhase]);
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30),
              onPressed: _quitBreathingExercise,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isCountingDown ? "$_countdown" : phaseText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  double phaseProgress = _isCountingDown
                      ? 0
                      : (_currentPhase / 4.0);
                  double animationOffset = _isCountingDown
                      ? 0
                      : (_progressController.value / 4.0);
                  double totalProgress = _isBreathingComplete
                      ? 1.0
                      : (phaseProgress + animationOffset);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: totalProgress,
                          strokeWidth: 12,
                          color: Colors.blue,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      _isLoadingAvatar
                          ? const SizedBox(width: 180, height: 180)
                          : Image.asset(
                              'assets/icon-mindf-$_petAvatar.png',
                              height: 180,
                            ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Text("$_currentCycle/4", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              const Text(
                "Box breathing",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhaseStep(
                    "4s",
                    "Inhale",
                    isActive: _currentPhase == 0 && !_isCountingDown,
                  ),
                  _buildPhaseStep(
                    "4s",
                    "Hold",
                    isActive: _currentPhase == 1 && !_isCountingDown,
                  ),
                  _buildPhaseStep(
                    "4s",
                    "Exhale",
                    isActive: _currentPhase == 2 && !_isCountingDown,
                  ),
                  _buildPhaseStep(
                    "4s",
                    "Hold",
                    isActive: _currentPhase == 3 && !_isCountingDown,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (_isBreathingComplete)
                ElevatedButton(
                  onPressed: () => setState(() => _isExerciseActive = false),
                  child: const Text("Finish"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseStep(String time, String label, {bool isActive = false}) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF455A64) : Colors.black38,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF455A64) : Colors.black38,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _breathingTimer?.cancel();
    _musicPlayer.dispose();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
