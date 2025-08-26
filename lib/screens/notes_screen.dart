import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import 'home_screen.dart'; // ✅ import HomeScreen (adjust path if needed)

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final service = NotesService();
    final notes = await service.readNotes();
    setState(() {
      _notes = notes.reversed.toList();
    });
  }

  Future<void> _saveNote() async {
    final note = _controller.text.trim();
    if (note.isNotEmpty) {
      final service = NotesService();
      await service.writeNote(note);
      _controller.clear();
      _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved!')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Optional: show dialog or help
            },
          ),
        ],
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.blue[600],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Push content down toward the middle
            const Spacer(flex: 1),

            // Title
            const Text(
              'Want to add a note?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Text Field
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Type how you’re feeling...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button (centered)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: _saveNote,
              child: const Text(
                'Save Note',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            const SizedBox(height: 12),

            // Skip button under Save -> go to HomeScreen
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),

            // Past Notes
            const Text(
              'Your Past Notes:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              flex: 3,
              child: _notes.isEmpty
                  ? const Center(
                child: Text(
                  'No notes yet. Start writing something.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.separated(
                itemCount: _notes.length,
                separatorBuilder: (_, __) =>
                const Divider(color: Colors.white24),
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    _notes[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
