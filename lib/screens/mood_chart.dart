import 'package:flutter/material.dart';

class MoodChart extends StatefulWidget { // Renamed from MoodCheckInScreen
  const MoodChart({super.key});

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart> {
  // UI colors
  static const Color primaryBlue = Color(0xFF2D7AF8); // screen background
  static const Color darkNavy   = Color(0xFF0B1F3F); // for Next button
  static const Color yellow     = Color(0xFFFFE08A);
  static const Color mint       = Color(0xFFA8E6CF);
  static const Color pink       = Color(0xFFFFB3C1);

  // Emoji grid model
  final List<_Mood> moods = const [
    _Mood(label: 'Awesome', emoji: '😄',  bg: yellow),
    _Mood(label: 'Good',    emoji: '🙂',  bg: yellow),
    _Mood(label: 'Okay',    emoji: '🙁',  bg: yellow),
    _Mood(label: 'Neutral', emoji: '😐',  bg: mint),
    _Mood(label: 'Bad',     emoji: '☹️',  bg: yellow),
    _Mood(label: 'Sad',     emoji: '😢',  bg: pink),
    _Mood(label: 'Tired',   emoji: '🥱',  bg: mint),
    _Mood(label: 'Stressed',emoji: '😟',  bg: yellow),
    _Mood(label: 'Angry',   emoji: '😠',  bg: yellow),
  ];

  int? selectedIndex; // which mood user tapped
  bool customSelected = false;

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
                  Text('Tap a mood to select it. You can also choose “Custom”.')
                ],
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                'Mood Check-In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(.25),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of emoji moods
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: moods.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: .82,
                  ),
                  itemBuilder: (ctx, i) => _MoodTile(
                    mood: moods[i],
                    selected: selectedIndex == i && !customSelected,
                    onTap: () {
                      setState(() {
                        selectedIndex = i;
                        customSelected = false;
                      });
                    },
                  ),
                ),
              ),
            ),

            // Custom big circle
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 18),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = null;
                    customSelected = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: customSelected ? Colors.black87 : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
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

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: (selectedIndex != null || customSelected)
                      ? () {
                    final choice = customSelected
                        ? 'Custom'
                        : moods[selectedIndex!].label;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $choice')),
                    );
                    // TODO: Navigate to Add Notes screen, etc.
                  }
                      : null,
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              mood.emoji,
              style: const TextStyle(fontSize: 40),
            ),
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
