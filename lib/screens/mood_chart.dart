import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodly/services/mood_service.dart';
import 'notes_screen.dart';

class MoodChart extends StatefulWidget {
  final bool fromHomeScreen;

  const MoodChart({super.key, this.fromHomeScreen = false});

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart> {
  // UI colors
  static const Color primaryBlue = Color(0xFF2D7AF8);
  static const Color darkNavy = Color(0xFF0B1F3F);
  static const Color yellow = Color(0xFFFFE08A);
  static const Color mint = Color(0xFFA8E6CF);
  static const Color pink = Color(0xFFFFB3C1);

  // Built-in moods
  final List<_Mood> moods = const [
    _Mood(label: 'Awesome', emoji: '😄', bg: yellow),
    _Mood(label: 'Good', emoji: '🙂', bg: yellow),
    _Mood(label: 'Okay', emoji: '🙁', bg: yellow),
    _Mood(label: 'Neutral', emoji: '😐', bg: mint),
    _Mood(label: 'Bad', emoji: '☹️', bg: yellow),
    _Mood(label: 'Sad', emoji: '😢', bg: pink),
    _Mood(label: 'Tired', emoji: '🥱', bg: mint),
    _Mood(label: 'Stressed', emoji: '😟', bg: yellow),
    _Mood(label: 'Angry', emoji: '😠', bg: yellow),
  ];

  // Current selection
  int? selectedIndex;              // built-in mood index
  bool customSelected = false;     // visual ring on big "Custom" circle
  CustomMood? _customMood;         // chosen custom mood (drives Next enabled)

  // Persisted custom moods
  static const _prefsKeyCustomMoods = 'custom_moods';
  final List<CustomMood> _customMoods = [];

  @override
  void initState() {
    super.initState();
    _loadCustomMoods();
  }

  Future<void> _loadCustomMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKeyCustomMoods) ?? [];
    final loaded = raw
        .map((s) => CustomMood.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    if (!mounted) return;
    setState(() {
      _customMoods
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _saveCustomMood(CustomMood mood) async {
    // Keep latest first, cap to 12
    _customMoods.removeWhere((m) =>
    m.emoji == mood.emoji && m.label == mood.label && m.bgColor == mood.bgColor);
    _customMoods.insert(0, mood);
    if (_customMoods.length > 12) {
      _customMoods.removeRange(12, _customMoods.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKeyCustomMoods,
      _customMoods.map((m) => jsonEncode(m.toJson())).toList(growable: false),
    );
  }

  bool get _hasSelection => selectedIndex != null || _customMood != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Moodly',
                applicationVersion: '0.1',
                children: const [
                  Text('Tap a mood to select it. You can also choose “Custom”.'),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Mood Check-In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: .25),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How are you feeling?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 18),

              // Grid (shrinkWrap so page scrolls as one)
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: .82,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: List.generate(moods.length, (i) {
                  return _MoodTile(
                    mood: moods[i],
                    selected: selectedIndex == i && _customMood == null,
                    onTap: () {
                      setState(() {
                        selectedIndex = i;
                        _customMood = null;     // built-in overrides custom
                        customSelected = false; // only a visual ring flag
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 18),

              // Big "Custom" circle
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final result = await showModalBottomSheet<CustomMood>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _CustomMoodSheet(),
                    );
                    if (result != null) {
                      await _saveCustomMood(result);
                      if (!mounted) return;
                      setState(() {
                        selectedIndex = null;     // no built-in
                        _customMood = result;     // ✅ drives Next enabled
                        customSelected = true;    // visual ring on circle
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Custom mood saved: ${result.label}')),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: customSelected ? Colors.black87 : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Saved custom moods header + row (with hint when empty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Your custom moods',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: _customMoods.isEmpty
                        ? const Center(
                      child: Text(
                        'Tap “Custom” to create and save your own moods.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    )
                        : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemCount: _customMoods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final cm = _customMoods[i];
                        final selected = _customMood != null &&
                            _customMood!.emoji == cm.emoji &&
                            _customMood!.label == cm.label &&
                            _customMood!.bgColor == cm.bgColor;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = null;
                              _customMood = cm;   // ✅ enables Next
                              customSelected = false; // ring stays on big circle only
                            });
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Color(cm.bgColor),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? Colors.black87 : Colors.black26,
                                    width: selected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(cm.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  cm.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Next button (always visible since page scrolls)
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _hasSelection
                      ? () async {
                    final moodService = MoodService();

                    try {
                      String? entryId;
                      if (_customMood != null) {
                        await _saveCustomMood(_customMood!);
                        entryId = await moodService.saveMoodEntry(
                          moodEmoji: _customMood!.emoji,
                          moodLabel: _customMood!.label,
                        );
                      } else {
                        final selectedMood = moods[selectedIndex!];
                        entryId = await moodService.saveMoodEntry(
                          moodEmoji: selectedMood.emoji,
                          moodLabel: selectedMood.label,
                        );
                      }

                      if (!mounted) return;

                      // Check if came from home screen
                      if (widget.fromHomeScreen) {
                        Navigator.pop(context);
                      } else {
                        // Regular flow: go to notes screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotesScreen(
                              moodEntryId: entryId,
                              moodEmoji: _customMood != null ? _customMood!.emoji : moods[selectedIndex!].emoji,
                              moodLabel: _customMood != null ? _customMood!.label : moods[selectedIndex!].label,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save mood: $e')),
                      );
                    }
                  }
                      : null,
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Mood grid tile --------------------------- */

class _MoodTile extends StatelessWidget {
  final _Mood mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: mood.bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black87 : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 8),
          Text(
            mood.label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mood {
  final String label;
  final String emoji;
  final Color bg;
  const _Mood({required this.label, required this.emoji, required this.bg});
}

/* ===================== Custom Mood Creator (Bottom Sheet) ===================== */

class CustomMood {
  final String emoji; // e.g. '🤗'
  final String label; // e.g. 'Grateful'
  final int bgColor;  // Color value

  CustomMood({
    required this.emoji,
    required this.label,
    required this.bgColor,
  });

  Map<String, dynamic> toJson() => {'emoji': emoji, 'label': label, 'bgColor': bgColor};

  factory CustomMood.fromJson(Map<String, dynamic> json) => CustomMood(
    emoji: json['emoji'] as String,
    label: json['label'] as String,
    bgColor: json['bgColor'] as int,
  );
}

class _CustomMoodSheet extends StatefulWidget {
  const _CustomMoodSheet();

  @override
  State<_CustomMoodSheet> createState() => _CustomMoodSheetState();
}

class _CustomMoodSheetState extends State<_CustomMoodSheet> {
  final TextEditingController _labelCtrl = TextEditingController();
  String _emoji = '🤗';
  Color _color = const Color(0xFFFFE08A); // default yellow

  // Small curated emoji set
  final List<String> _emojis = const [
    '🤗','🥹','😴','🤯','🤨','🤩','😭','😤','😟','😌','😇','🫠','😵‍💫','😎','🤒'
  ];

  final List<Color> _palette = const [
    Color(0xFFFFE08A), // yellow
    Color(0xFFA8E6CF), // mint
    Color(0xFFFFB3C1), // pink
    Color(0xFFB3E5FC), // light blue
    Color(0xFFD1C4E9), // lavender
    Color(0xFFFFF59D), // soft yellow
  ];

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Create a custom mood',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Emoji row
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final e = _emojis[i];
                  final selected = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.black12 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.black54 : Colors.black26,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Color palette
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _palette.map((c) {
                final selected = c.value == _color.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.black12,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelCtrl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'e.g., Grateful, Drained, Calm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                  alignment: Alignment.center,
                  child: Text(_emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 12),
                Text(
                  _labelCtrl.text.isEmpty ? 'Custom' : _labelCtrl.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final mood = CustomMood(
                        emoji: _emoji,
                        label: _labelCtrl.text.trim().isEmpty
                            ? 'Custom'
                            : _labelCtrl.text.trim(),
                        bgColor: _color.value,
                      );
                      Navigator.pop(context, mood);
                    },
                    child: const Text('Use Mood'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
