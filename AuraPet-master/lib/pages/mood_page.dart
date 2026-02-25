import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 1. Import Models & Utils
import '../models/mood_entry.dart';
import '../utils/mood_constants.dart';

// 2. Import Your New Widgets
import '../widgets/glass_card.dart';
import '../widgets/mood_calendar.dart';
import '../widgets/weekly_mood_chart.dart';
import '../widgets/mood_recommendation_card.dart';
import '../widgets/mood_action_buttons.dart';
import '../widgets/mood_todo_list.dart';
import '../services/user_service.dart';
import 'profile_page.dart'; // For AppState

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  // --- STATE VARIABLES ---
  static String? _cachedAvatar;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentTime = DateTime.now();
  late Timer _timer;
  String? _userId;
  String _avatarAsset = 'assets/penguin.png';
  bool _isLoadingAvatar = true;
  final UserService _userService = UserService();

  // Dialog Controllers
  final TextEditingController _noteController = TextEditingController();
  String? _tempSelectedMoodLabel;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadAvatar();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndOpenDialogForToday();
    });
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
  void dispose() {
    _timer.cancel();
    _noteController.dispose();
    super.dispose();
  }

  // --- LOGIC HELPERS ---

  String _getDateId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Helper to check if two dates represent the same calendar day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String get _formattedTime {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  MoodEntry? _getLogForDate(List<MoodEntry> logs, DateTime date) {
    try {
      return logs.firstWhere((log) => _isSameDay(log.timestamp, date));
    } catch (e) {
      return null;
    }
  }

  // --- DIALOGS ---
  Future<void> _checkAndOpenDialogForToday() async {
    if (_userId == null) return;

    final today = DateTime.now();
    final docId = _getDateId(today);
    final doc = await FirebaseFirestore.instance
        .collection('User-Module')
        .doc(_userId)
        .collection('mood_logs')
        .doc(docId)
        .get();

    if (!doc.exists && mounted) {
      _openMoodSelectorDialog(today);
    }
  }

  // UPDATED: Generic error message for both Past and Future
  void _showEditRestrictionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("You can only edit entries for today! 📅"),
        backgroundColor: Colors.redAccent.shade200,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMoodSelectorDialog(DateTime date) async {
    // UPDATED: STRICT CHECK - Only allow if the date is TODAY
    if (!_isSameDay(date, DateTime.now())) {
      _showEditRestrictionError();
      return; // Stop execution
    }

    MoodEntry? existingLog;
    _tempSelectedMoodLabel = existingLog?.moodLabel;

    Color getHeaderColor(String? label) {
      if (label == null) return Colors.deepPurple.shade400;
      return moodOptions.firstWhere((m) => m['label'] == label)['color'];
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final currentColor = getHeaderColor(_tempSelectedMoodLabel);
            return Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: _isLoadingAvatar
                                  ? const SizedBox(width: 40, height: 40)
                                  : Image.asset(
                                      _avatarAsset,
                                      height: 40,
                                      width: 40,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "How are you?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${date.day}/${date.month}/${date.year}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Mood Grid
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: moodOptions.map((option) {
                            final isSelected =
                                _tempSelectedMoodLabel == option['label'];
                            return GestureDetector(
                              onTap: () => setStateDialog(
                                () => _tempSelectedMoodLabel = option['label'],
                              ),
                              child: AnimatedScale(
                                scale: isSelected ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 70,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (option['color'] as Color)
                                              .withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? option['color']
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (option['color'] as Color)
                                                  .withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        option['icon'],
                                        color: option['color'],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        option['label'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? option['color']
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _tempSelectedMoodLabel == null
                                    ? null
                                    : () => _saveMood(date),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text("Save"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) => Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: child,
      ),
    );
  }

  void _openDiaryDialog(DateTime date) async {
    // UPDATED: STRICT CHECK - Only allow if the date is TODAY
    if (!_isSameDay(date, DateTime.now())) {
      _showEditRestrictionError();
      return; // Stop execution
    }

    // Fetch current note for this date to pre-fill
    final docId = _getDateId(date);
    final doc = await FirebaseFirestore.instance
        .collection('User-Module')
        .doc(_userId)
        .collection('mood_logs')
        .doc(docId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _noteController.text = data['note'] ?? '';
    } else {
      _noteController.text = '';
    }

    String monthName(int m) {
      const names = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ];
      return names[m - 1];
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "My Diary",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${date.day} ${monthName(date.month)} ${date.year}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: TextField(
                        controller: _noteController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText:
                              "Share your thoughts, feelings, or what happened today...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _saveDiary(date),
                            label: const Text("Save Entry"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) => Transform.scale(
        scale: Curves.easeOutCubic.transform(anim1.value),
        child: Opacity(opacity: anim1.value, child: child),
      ),
    );
  }

  // --- SAVE LOGIC ---
  Future<void> _saveMood(DateTime date) async {
    if (_userId == null) {
      print('❌ ERROR: User ID is null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final option = moodOptions.firstWhere(
        (m) => m['label'] == _tempSelectedMoodLabel,
      );

      final Map<String, dynamic> dataToSave = {
        'timestamp': Timestamp.fromDate(date),
        'moodLabel': option['label'],
        'iconCodePoint': (option['icon'] as IconData).codePoint,
        'iconFontFamily': (option['icon'] as IconData).fontFamily,
        'colorValue': (option['color'] as Color).value,
      };

      final docId = _getDateId(date);
      print('😊 Saving mood from mood_page: docId=$docId, userId=$_userId');
      print('😊 Mood: ${option['label']}');
      print('😊 Data: $dataToSave');

      await FirebaseFirestore.instance
          .collection('User-Module')
          .doc(_userId)
          .collection('mood_logs')
          .doc(docId)
          .set(dataToSave, SetOptions(merge: true));

      print('✅ Mood saved successfully to Firebase!');
      print('✅ Path: User-Module/$_userId/mood_logs/$docId');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ ERROR saving mood: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDiary(DateTime date) async {
    if (_userId == null) {
      print('❌ ERROR: User ID is null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final docId = _getDateId(date);
      print('📓 Saving diary from mood_page: docId=$docId, userId=$_userId');
      print('📓 Note content: ${_noteController.text}');

      final Map<String, dynamic> dataToSave = {
        'timestamp': Timestamp.fromDate(date),
        'note': _noteController.text,
      };
      print('📓 Data: $dataToSave');

      await FirebaseFirestore.instance
          .collection('User-Module')
          .doc(_userId)
          .collection('mood_logs')
          .doc(docId)
          .set(dataToSave, SetOptions(merge: true));

      print('✅ Diary saved successfully to Firebase!');
      print('✅ Path: User-Module/$_userId/mood_logs/$docId');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ ERROR saving diary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving diary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ... (Build method and other widgets)
  @override
  Widget build(BuildContext context) {
    // ... (Your existing build method code)
    // This part does not need changes, just the dialog logic above.
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mood Diary",
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg-mood.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('User-Module')
                .doc(_userId)
                .collection('mood_logs')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(child: Text("Error loading moods"));

              final List<MoodEntry> moodLogs = snapshot.hasData
                  ? snapshot.data!.docs
                        .map(
                          (doc) => MoodEntry.fromMap(
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : [];

              final selectedLog = _getLogForDate(moodLogs, _selectedDate);
              final hasEntry =
                  selectedLog != null && selectedLog.moodLabel != 'Unknown';

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  GlassCard(
                    child: MoodCalendar(
                      logs: moodLogs,
                      selectedDate: _selectedDate,
                      onDateSelected: (d) => setState(() => _selectedDate = d),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildHeaderRow(selectedLog, hasEntry),
                          const SizedBox(height: 24),
                          MoodActionButtons(
                            selectedLog: selectedLog,
                            onLogTap: () =>
                                _openMoodSelectorDialog(_selectedDate),
                            onDiaryTap: () => _openDiaryDialog(_selectedDate),
                          ),
                          if (hasEntry && selectedLog.note.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildNoteDisplay(selectedLog.note),
                          ],
                          if (selectedLog != null &&
                              selectedLog.aiSummary.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildAISummaryDisplay(selectedLog.aiSummary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MoodTodoList(
                    userId: _userId ?? '',
                    // This ensures the To-Do list updates when you change dates on the calendar
                    dateId: _getDateId(_selectedDate),
                  ),
                  const SizedBox(height: 24),
                  if (hasEntry) ...[
                    MoodRecommendationCard(log: selectedLog),
                    const SizedBox(height: 24),
                  ],

                  WeeklyMoodChart(
                    allLogs: moodLogs,
                    selectedDate: _selectedDate,
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ... (Your Helper Widgets _buildHeaderRow and _buildNoteDisplay remain the same)
  Widget _buildHeaderRow(MoodEntry? selectedLog, bool hasEntry) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hasEntry ? "Feeling ${selectedLog!.moodLabel}" : "How are you?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasEntry
                    ? "Tap 'Edit' if your mood changes."
                    : "Take a moment to check in with yourself.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple.shade800.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _isLoadingAvatar
            ? const SizedBox(width: 100, height: 100)
            : Image.asset(
                _avatarAsset,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
      ],
    );
  }

  Widget _buildNoteDisplay(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Diary Note:",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryDisplay(String aiSummary) {
    return _ExpandableAISummary(aiSummary: aiSummary);
  }
}

class _ExpandableAISummary extends StatefulWidget {
  final String aiSummary;

  const _ExpandableAISummary({required this.aiSummary});

  @override
  State<_ExpandableAISummary> createState() => _ExpandableAISummaryState();
}

class _ExpandableAISummaryState extends State<_ExpandableAISummary> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Colors.teal.shade700),
              const SizedBox(width: 4),
              Text(
                "AI Diary Summary:",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.aiSummary,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              fontStyle: FontStyle.italic,
            ),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (widget.aiSummary.length > 100) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
