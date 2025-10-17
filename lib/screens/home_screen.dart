import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notes_service.dart';
import '../services/mood_service.dart';
import 'landing_screen.dart';
import 'mood_chart.dart';
import 'mood_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _noteController = TextEditingController();
  final _rng = Random();

  List<String> _allQuotes = [];
  List<int> _deck = [];
  int _cursor = 0;
  String _currentQuote = "You can make any day a good day.";
  Timer? _ticker;

  String _todayMoodEmoji = '?';
  String _todayMoodLabel = 'Log your mood';
  bool _hasMoodToday = false;
  String? _todayEntryId;

  // Reusable constants
  static const _whiteBold = TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600);
  static const _whiteText = TextStyle(color: Colors.white);
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const _buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));

  @override
  void initState() {
    super.initState();
    _initQuotes();
    _loadTodayMood();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayMood() async {
    try {
      final entries = await MoodService().getMoodEntries();
      final now = DateTime.now();
      final todayEntry = entries.firstWhere(
            (e) => e.timestamp.year == now.year && e.timestamp.month == now.month && e.timestamp.day == now.day,
        orElse: () => throw Exception('No mood today'),
      );

      if (!mounted) return;
      setState(() {
        _todayMoodEmoji = todayEntry.moodEmoji;
        _todayMoodLabel = todayEntry.moodLabel;
        _hasMoodToday = true;
        _todayEntryId = todayEntry.id;
        _noteController.text = todayEntry.note ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _todayMoodEmoji = '?';
        _todayMoodLabel = 'Log your mood';
        _hasMoodToday = false;
        _todayEntryId = null;
        _noteController.clear();
      });
    }
  }

  Future<void> _initQuotes() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      _allQuotes = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      _allQuotes = ["Breathe. Start small. You've got this.", "Progress over perfection.", "You can restart your day at any moment."];
    }

    _reshuffleDeck();
    _setNextQuote();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? _setNextQuote() : null);
  }

  void _reshuffleDeck() {
    _deck = List.generate(_allQuotes.length, (i) => i)..shuffle(_rng);
    _cursor = 0;
  }

  void _setNextQuote() {
    if (_allQuotes.isEmpty) return;
    if (_cursor >= _deck.length) _reshuffleDeck();
    setState(() => _currentQuote = _allQuotes[_deck[_cursor++]]);
  }

  void _saveNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) {
      _showSnackBar("Please enter a note first");
      return;
    }

    if (!_hasMoodToday || _todayEntryId == null) {
      _showSnackBar("Please log your mood first by tapping the ? icon");
      return;
    }

    try {
      await MoodService().addNoteToEntry(_todayEntryId!, noteText, _todayMoodEmoji);
      final notesService = NotesService();
      final encoded = NotesService.encodeWithEmoji(_todayMoodEmoji, noteText);
      await notesService.writeNote(encoded);
      await _loadTodayMood();
      _showSnackBar("Note saved!");
    } catch (e) {
      _showSnackBar("Failed to save: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
            (route) => false,
      );
    } catch (e) {
      _showSnackBar('Failed to log out. Please try again.');
    }
  }

  Widget _buildNavButton(IconData icon, String label, String route, {bool isMoodChart = false}) {
    return InkWell(
      onTap: () async {
        if (isMoodChart) {
          // Regular mood chart navigation (not from home screen)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MoodChart(fromHomeScreen: false),
            ),
          );
        } else {
          await Navigator.pushNamed(context, route);
        }
        if (route == '/mood_chart' || isMoodChart) _loadTodayMood();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 4),
            Text(label, style: _whiteText),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return InkWell(
      onTap: () async {
        // Load real mood entries
        final moodService = MoodService();
        final moodModels = await moodService.getMoodEntries();

        // Convert to MoodEntry format
        final entries = moodModels.map((model) => MoodEntry(
          date: model.timestamp,
          emoji: model.moodEmoji,
          label: model.moodLabel,
          note: model.note,
          score: _moodToScore(model.moodLabel),
        )).toList();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MoodHistoryScreen(entries: entries),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white, size: 36),
            SizedBox(height: 4),
            Text('History', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  int _moodToScore(String label) {
    const scores = {
      'Awesome': 5,
      'Good': 4,
      'Okay': 3,
      'Neutral': 3,
      'Bad': 2,
      'Sad': 1,
      'Tired': 2,
      'Stressed': 2,
      'Angry': 1,
    };
    return scores[label] ?? 3; // Default to 3 for custom moods
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool primary = true}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: primary ? Colors.blueAccent : Colors.white.withOpacity(0.2),
        padding: _buttonPadding,
        shape: _buttonShape,
      ),
      child: Text(text, style: _whiteBold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: Colors.black),
              onSelected: (value) {
                if (value == 'settings') Navigator.pushNamed(context, '/settings');
                else if (value == 'logout') _logout();
                else if (value == 'about') showAboutDialog(
                  context: context,
                  applicationName: 'Moodly',
                  applicationVersion: '0.1.0',
                  applicationIcon: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.favorite, color: Colors.purple),
                  ),
                  children: const [
                    SizedBox(height: 8),
                    Text('Moodly helps you track your mood, jot quick notes, and reflect over time. Built with Flutter & Firebase.'),
                  ],
                );
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'about', child: Text('About')),
                PopupMenuItem(value: 'logout', child: Text('Log Out')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Mood", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        if (!_hasMoodToday) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MoodChart(fromHomeScreen: true),
                            ),
                          );
                          await _loadTodayMood();  // Just add 'await' here
                        }
                      },
                      borderRadius: BorderRadius.circular(40),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.yellow,
                            child: Text(_todayMoodEmoji, style: const TextStyle(fontSize: 40)),
                          ),
                          const SizedBox(height: 10),
                          Text(_todayMoodLabel, style: _whiteText, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        height: 100,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(border: InputBorder.none, hintText: "Today's notes..."),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _hasMoodToday
                      ? [
                    _buildButton("New Note", () async {
                      // Reset everything as if user never logged a mood today
                      setState(() {
                        _noteController.clear();
                        _todayMoodEmoji = '?';
                        _todayMoodLabel = 'Log your mood';
                        _hasMoodToday = false;
                        _todayEntryId = null;
                      });
                      FocusScope.of(context).requestFocus(FocusNode());
                      _showSnackBar("Starting fresh! Tap the ? to log your mood");
                    }, primary: false),
                    const SizedBox(width: 12),
                    _buildButton(_noteController.text.trim().isEmpty ? "Add Note" : "Update Note", _saveNote),
                  ]
                      : [_buildButton("Add Note", () => _showSnackBar("Please log your mood first by tapping the ? icon"), primary: false)],
                ),
                const SizedBox(height: 30),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(_currentQuote, key: ValueKey(_currentQuote), style: _whiteText.copyWith(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/mountains.jpg', height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(color: Colors.blue[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavButton(Icons.emoji_emotions, 'Mood Chart', '/mood_chart', isMoodChart: true),  // ADD isMoodChart: true
                      _buildNavButton(Icons.alarm, 'Reminders', '/reminders'),
                      _buildNavButton(Icons.note, 'Notes', '/notes'),
                      _buildNavButton(Icons.person, 'Profile', '/account'),
                      _buildHistoryButton(),
                      _buildNavButton(Icons.settings, 'Settings', '/settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}