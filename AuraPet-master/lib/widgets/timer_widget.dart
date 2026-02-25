import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

enum TimerState { initial, running, paused }

class TimerWidget extends StatefulWidget {
  final void Function(TimerState)? onStateChanged;

  const TimerWidget({super.key, this.onStateChanged});
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Duration _duration = const Duration(minutes: 45);
  Duration _initialDuration = const Duration(minutes: 45);
  Timer? _timer;
  TimerState _state = TimerState.initial;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
    setState(() {
      _state = TimerState.running;
    });
    widget.onStateChanged?.call(_state);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _state = TimerState.paused;
    });
    widget.onStateChanged?.call(_state);
  }

  void _restartTimer() {
    _timer?.cancel();
    setState(() {
      _duration = _initialDuration;
      _state = TimerState.initial;
    });
    widget.onStateChanged?.call(_state);
  }

  void _updateTimer() {
    if (_duration.inSeconds == 0) {
      _restartTimer();
    } else {
      setState(() {
        _duration -= const Duration(seconds: 1);
      });
    }
  }

  void _showTimePicker() {
    Duration tempDuration = _duration;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 330,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, -3),
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              const Text(
                "Set Timer",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF3B3B3B),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _duration,
                  onTimerDurationChanged: (Duration newDuration) {
                    tempDuration = newDuration;
                  },
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _duration = tempDuration;
                        _initialDuration = tempDuration;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffd5d0c3),
                      foregroundColor: Colors.black,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));

    return Column(
      mainAxisSize: MainAxisSize.min, // so it doesn’t take full height
      children: [
        const SizedBox(height: 490), // keep spacing
        GestureDetector(
          onTap: _state == TimerState.running ? null : _showTimePicker,
          child: Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20), // adjust spacing as needed
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_state == TimerState.initial)
              ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Start Now'),
              ),
            if (_state == TimerState.running)
              ElevatedButton(
                onPressed: _pauseTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Pause'),
              ),
            if (_state == TimerState.paused) ...[
              ElevatedButton(
                onPressed: _startTimer, // resume
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Resume'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _restartTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Restart'),
              ),
            ]
          ],
        ),
      ],
    );
  }
}
