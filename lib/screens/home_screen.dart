import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notes_service.dart';
import 'landing_screen.dart';
import 'mood_chart.dart';
import 'mood_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _noteController = TextEditingController();

  // ---- Quotes state ----
  final _rng = Random();
  List<String> _allQuotes = [];
  List<int> _deck = []; // shuffled indices, consumed one-by-one
  int _cursor = 0;
  String _currentQuote = "You can make any day a good day.";
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _initQuotes();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initQuotes() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.txt');
      final lines = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) _allQuotes = lines;
    } catch (_) {
      _allQuotes = [
        "Breathe. Start small. You’ve got this.",
        "Progress over perfection.",
        "You can restart your day at any moment."
      ];
    }

    _reshuffleDeck();
    _setNextQuote(immediate: true);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _setNextQuote();
    });
  }

  void _reshuffleDeck() {
    _deck = List<int>.generate(_allQuotes.length, (i) => i)..shuffle(_rng);
    _cursor = 0;
  }

  void _setNextQuote({bool immediate = false}) {
    if (_allQuotes.isEmpty) return;
    if (_cursor >= _deck.length) _reshuffleDeck();
    final idx = _deck[_cursor++];
    final next = _allQuotes[idx];

    setState(() {
      _currentQuote = next;
    });
    // Fade is handled by AnimatedSwitcher via ValueKey change.
  }

  void _saveNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isNotEmpty) {
      final notesService = NotesService();
      await notesService.writeNote(noteText);
      _noteController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note saved!")),
      );
    }
  }

  void _showAbout() {
    showAboutDialog(
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
        Text(
          'Moodly helps you track your mood, jot quick notes, and reflect over time. '
          'Built with Flutter & Firebase.',
        ),
      ],
    );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
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
                if (value == 'settings') {
                  Navigator.pushNamed(context, '/settings');
                } else if (value == 'logout') {
                  _logout();
                } else if (value == 'about') {
                  _showAbout();
                }
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
                const Text(
                  "Today's Mood",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.yellow,
                          child: Icon(Icons.sentiment_satisfied,
                              size: 50, color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Awesome',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Today's notes...",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _saveNote,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add Note",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Animated quote (fades when text changes)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    _currentQuote,
                    key: ValueKey(_currentQuote),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/mountains.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/mood_chart'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_emotions, color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text('Mood Chart',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/reminders'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm, color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text('Reminders',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/notes'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.note, color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text('Notes',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/account'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text('Profile',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings,
                                  color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text('Settings',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
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