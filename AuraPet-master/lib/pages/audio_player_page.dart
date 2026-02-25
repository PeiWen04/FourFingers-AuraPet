import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sleep_story.dart';
import 'rating_page.dart';
import 'dart:async';
import 'dart:ui';
import '../services/user_service.dart';

class AudioPlayerPage extends StatefulWidget {
  final List<SleepStory> stories;
  final int initialIndex;

  const AudioPlayerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Timer? _ratingTimer;
  bool _isRating = false;
  String _avatarAsset = 'assets/penguin.png';
  String _sleepingAvatar = 'assets/sleeping_penguin.png';
  bool _isAvatarLoading = true;
  final UserService _userService = UserService();

  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<PlayerState> _playerStateSubscription;
  late AppLifecycleListener _lifecycleListener;

  SleepStory get _currentStory => widget.stories[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _loadAvatar();

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        if (mounted) setState(() => _isLoading = true);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }

      if (!state.playing && !_isRating) {
        _ratingTimer?.cancel();
        _ratingTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            _navigateToRatingPage();
          }
        });
      } else {
        _ratingTimer?.cancel();
      }

      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }

      if (mounted) {
        setState(() {});
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onHide: () => _audioPlayer.stop(),
    );
  }

  final Map<String, String> _sleepingAvatarMap = {
    'assets/penguin.png': 'assets/sleeping_penguin.png',
    'assets/owl.png': 'assets/sleeping_owl.png',
  };

  Future<void> _loadAvatar() async {
     if (!mounted) return;
     setState(() {
       _isAvatarLoading = true;
     });
     final avatar = await _userService.getAvatar();

     if (!mounted) return;
     setState(() {
       _avatarAsset = avatar;
       _sleepingAvatar = _sleepingAvatarMap[avatar] ?? avatar;
       _isAvatarLoading = false;
     });
   }

  Future<void> _initAudioPlayer() async {
    _loadAvatar();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    if (_currentStory.audioLink.isNotEmpty) {
      try {
        // Log the URL being used to confirm it's correct
        print('Attempting to set audio URL: ${_currentStory.audioLink}');

        await _audioPlayer.setUrl(_currentStory.audioLink);
        _audioPlayer.play();
      } catch (e) {
        // Log the specific error to the console
        print('Error setting audio URL: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          // Show a Snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading audio: Please check your connection or try another story.'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playNext() {
    if (_currentIndex < widget.stories.length - 1) {
      if (mounted) {
        setState(() => _currentIndex++);
        _initAudioPlayer();
      }
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      if (mounted) {
        setState(() => _currentIndex--);
        _initAudioPlayer();
      }
    }
  }

  void _navigateToRatingPage() async {
    if (_isRating) return;
    _isRating = true;
    _ratingTimer?.cancel();
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    }

    final newRating = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => RatingPage(storyId: _currentStory.id)),
    );

    _isRating = false;

    if (newRating != null && mounted) {
      setState(() {
        _currentStory.rating = newRating.toDouble();
      });
      Navigator.of(context).pop(); // Go back to SleepPage
    } else if (mounted) {
      // If no rating was given, we pop the audio page anyway as per user request
      Navigator.of(context).pop();
    }
  }

  void _showTimerDialog() async {
    int selectedHours = 0;
    int selectedMinutes = 5;
    int selectedSeconds = 0;

    final hourController = FixedExtentScrollController(initialItem: selectedHours);
    final minuteController = FixedExtentScrollController(initialItem: selectedMinutes);
    final secondController = FixedExtentScrollController(initialItem: selectedSeconds);

    final result = await showDialog<Duration>(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          child: CupertinoPicker(
                            scrollController: hourController,
                            itemExtent: 50,
                            onSelectedItemChanged: (index) => selectedHours = index,
                            looping: true,
                            selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                              background: Colors.transparent,
                            ),
                            children: List.generate(
                                13,
                                (index) => Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 24)))),
                          ),
                        ),
                        const Text('h', style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: CupertinoPicker(
                            scrollController: minuteController,
                            itemExtent: 50,
                            looping: true,
                            onSelectedItemChanged: (index) => selectedMinutes = index,
                            selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                              background: Colors.transparent,
                            ),
                            children: List.generate(
                                60,
                                (index) => Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 24)))),
                          ),
                        ),
                        const Text('min', style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: CupertinoPicker(
                            scrollController: secondController,
                            itemExtent: 50,
                            looping: true,
                            onSelectedItemChanged: (index) => selectedSeconds = index,
                            selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                              background: Colors.transparent,
                            ),
                            children: List.generate(
                                60,
                                (index) => Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 24)))),
                          ),
                        ),
                        const Text('sec', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, Duration.zero);
                        },
                        child: const Text('Cancel Timer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final duration = Duration(hours: selectedHours, minutes: selectedMinutes, seconds: selectedSeconds);
                          Navigator.pop(context, duration);
                        },
                        child: const Text('Set Timer'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();

    _sleepTimer?.cancel();

    if (result != null) {
      if (result > Duration.zero) {
        if (!_audioPlayer.playing) {
          _audioPlayer.play();
        }

        setState(() {
          _sleepTimerRemaining = result;
        });
        _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _sleepTimerRemaining == null || _sleepTimerRemaining!.inSeconds <= 0) {
            timer.cancel();
            if (mounted && _audioPlayer.playing && (_sleepTimerRemaining?.inSeconds ?? 1) <= 0) {
              _audioPlayer.pause();
            }
            if (mounted) {
              setState(() {
                _sleepTimerRemaining = null;
              });
            }
          } else {
            if (_audioPlayer.playing) {
              setState(() {
                _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
              });
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sleep timer set for ${_formatDurationForSnackbar(result)}'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (_audioPlayer.playing) {
          _audioPlayer.pause();
        }
        setState(() {
          _sleepTimerRemaining = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep timer canceled'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatDurationForSnackbar(Duration duration) {
    List<String> parts = [];
    if (duration.inHours > 0) parts.add('${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}');
    if (duration.inMinutes.remainder(60) > 0) parts.add('${duration.inMinutes.remainder(60)} minute${duration.inMinutes.remainder(60) > 1 ? 's' : ''}');
    if (duration.inSeconds.remainder(60) > 0) parts.add('${duration.inSeconds.remainder(60)} second${duration.inSeconds.remainder(60) > 1 ? 's' : ''}');
    if (parts.isEmpty) return 'Timer not set';
    return parts.join(' ');
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ratingTimer?.cancel();
    _sleepTimer?.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _playerStateSubscription.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToRatingPage();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _audioPlayer.stop();
              Navigator.of(context).pop();
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg-sleep-night.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: 130,
                  height: 130,
                  color: Colors.purple.shade100,
                  child: _currentStory.image.isNotEmpty ? Image.network(_currentStory.image, fit: BoxFit.cover) : const Center(child: Text("Image")),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _currentStory.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentStory.author,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                    onPressed: () {
                      final newPosition = _position - const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 50),
                    onPressed: _currentIndex > 0 ? _playPrevious : null,
                  ),
                  const SizedBox(width: 4),
                  _isLoading
                      ? const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : IconButton(
                          icon: Icon(
                            _audioPlayer.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                          onPressed: () {
                            if (_audioPlayer.playing) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                        ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 50),
                    onPressed: _currentIndex < widget.stories.length - 1 ? _playNext : null,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                    onPressed: () {
                      final newPosition = _position + const Duration(seconds: 10);
                      if (newPosition < _duration) {
                        _audioPlayer.seek(newPosition);
                      } else {
                        _audioPlayer.seek(_duration);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 32),
                        onPressed: _showTimerDialog,
                      ),
                      SizedBox(
                        height: 18,
                        child: _sleepTimerRemaining != null && _sleepTimerRemaining! > Duration.zero
                            ? Text(
                                _formatDuration(_sleepTimerRemaining!),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 60), // adjust value
                    child: _isAvatarLoading
                         ? const SizedBox(
                             height: 150,
                             width: 150,
                           )
                         : Image.asset(
                             _sleepingAvatar,
                             height: 150,
                           ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/pillow.png'), // pillow background
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed: _navigateToRatingPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // let the pillow show through
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Rate Audio',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 7),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}
