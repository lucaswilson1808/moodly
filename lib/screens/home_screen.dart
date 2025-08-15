import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import 'mood_chart.dart'; // <-- make sure this file exports class MoodChart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isNotEmpty) {
      final notesService = NotesService();
      await notesService.writeNote(noteText);
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note saved!")),
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
                  // handle logout
                } else if (value == 'about') {
                  // maybe show a dialog or about page
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                      onPressed: () {
                        _saveNote();
                        Navigator.pushNamed(context, '/notes');
                      },
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
                const Text(
                  "You can make any day a good day.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // If this image path isn't set up in pubspec.yaml, comment it out to avoid errors.
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

                // ==== Bottom Bar ====
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
                      // Mood Chart (make tappable)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // If your class is named MoodScreen or MoodChartScreen,
                          // change MoodChart() below to match.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MoodChart(),
                            ),
                          );
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_emotions,
                                color: Colors.white, size: 36),
                            SizedBox(height: 4),
                            Text('Mood Chart',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),

                      // Profile (placeholder)
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 36),
                          SizedBox(height: 4),
                          Text('Profile',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),

                      // Settings (placeholder)
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.settings, color: Colors.white, size: 36),
                          SizedBox(height: 4),
                          Text('Settings',
                              style: TextStyle(color: Colors.white)),
                        ],
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
