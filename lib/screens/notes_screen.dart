import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/notes_service.dart';
import '../services/mood_service.dart';

class NotesScreen extends StatefulWidget {
  final String? moodEntryId;
  final String? moodEmoji;
  final String? moodLabel;

  const NotesScreen({
    super.key,
    this.moodEntryId,
    this.moodEmoji,
    this.moodLabel,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _input = TextEditingController();
  final _svc = NotesService();

  // We keep raw lines for persistence and a parsed list for UI.
  List<String> _raw = [];
  List<_NoteView> _items = [];
  bool _loading = true;

  // Quick emoji choices - make it mutable so we can add custom emoji
  List<String> _emojis = ['😀', '🙂', '😐', '😞', '😭', '🔥', '✨', '✅', '🧠', '📝'];
  String _selectedEmoji = '📝';

  @override
  void initState() {
    super.initState();

    // Add the mood emoji if it's not already in the list
    if (widget.moodEmoji != null && !_emojis.contains(widget.moodEmoji)) {
      _emojis = [..._emojis, widget.moodEmoji!];
    }

    // Set the selected emoji to the mood emoji if provided
    if (widget.moodEmoji != null) {
      _selectedEmoji = widget.moodEmoji!;
    }

    _load();
  }

  Future<void> _load() async {
    final lines = await _svc.readNotes();
    final parsed = _parse(lines);

    // Newest first for UI (file is oldest → newest)
    final reversedItems = parsed.reversed.toList();
    final reversedRaw = lines.reversed.toList();

    if (!mounted) return;
    setState(() {
      _raw = reversedRaw;
      _items = reversedItems;
      _loading = false;
    });
  }

  List<_NoteView> _parse(List<String> lines) {
    return lines.map((line) {
      final parts = line.split('|||');
      if (parts.length >= 2) {
        final emoji = parts.first.trim().isEmpty ? '📝' : parts.first.trim();
        final text = parts.sublist(1).join('|||').trim();
        return _NoteView(emoji: emoji, text: text, encoded: line);
      } else {
        // Back-compat: plain lines become 📝 notes
        return _NoteView(emoji: '📝', text: line.trim(), encoded: line);
      }
    }).toList();
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final encoded = NotesService.encodeWithEmoji(_selectedEmoji, text);
    await _svc.writeNote(encoded);

    // If no moodEntryId, create a default mood entry
    String? entryId = widget.moodEntryId;

    if (entryId == null) {
      try {
        final moodService = MoodService();
        entryId = await moodService.saveMoodEntry(
          moodEmoji: _selectedEmoji,
          moodLabel: 'Note',
        );
        debugPrint('✅ Created new mood entry: $entryId');
      } catch (e) {
        debugPrint('❌ Failed to create mood entry: $e');
      }
    }

    // Save note to the mood entry
    if (entryId != null) {
      try {
        final moodService = MoodService();
        await moodService.addNoteToEntry(entryId, text, _selectedEmoji);
        debugPrint('✅ Saved to Firebase!');
      } catch (e) {
        debugPrint('❌ Failed to save note to Firestore: $e');
      }
    }

    setState(() {
      _input.clear();
      _items.insert(0, _NoteView(emoji: _selectedEmoji, text: text, encoded: encoded));
      _raw.insert(0, encoded);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved!')),
      );
    }
  }

  Future<void> _deleteAt(int index) async {
    final newRaw = List<String>.from(_raw)..removeAt(index);
    // Write back to disk in oldest → newest order
    await _svc.rewriteNotes(newRaw.reversed.toList());

    if (!mounted) return;
    setState(() {
      _raw.removeAt(index);
      _items.removeAt(index);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors tuned to your screenshot
    final bg = Colors.blue[600];
    final cardFill = Colors.white;
    final hint = Colors.grey.shade700;
    final pill = const Color(0xFF1B2A84); // deep indigo btn

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: Colors.black,
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Moodly',
                applicationVersion: '0.1.0',
              );
            },
          ),
        ],
      ),
      body: Container(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Want to add a note?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Show selected mood
              if (widget.moodEmoji != null && widget.moodLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.moodEmoji!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Text(
                        widget.moodLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Rounded input box (large) - THIS WAS MISSING IN YOUR CODE
              Container(
                decoration: BoxDecoration(
                  color: cardFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _input,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type how you are feeling...",
                    hintStyle: TextStyle(color: hint),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Save / Skip row (pill button like screenshot)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pill,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Note',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Emoji selector kept, but subtle and compact under buttons
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final e = _emojis[i];
                    final selected = e == _selectedEmoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = e),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white.withOpacity(0.25) : Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white24,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Your Past Notes:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable notes area (white cards, newest first)
              Expanded(
                child: _loading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : _items.isEmpty
                    ? const Center(
                  child: Text(
                    'No notes yet. Start writing something.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Dismissible(
                      key: ValueKey(item.encoded + index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteAt(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.text,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
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
}

class _NoteView {
  final String emoji;
  final String text;
  final String encoded; // raw line for persistence mapping
  _NoteView({required this.emoji, required this.text, required this.encoded});
}