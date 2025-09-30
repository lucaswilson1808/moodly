import 'package:flutter/material.dart';

/// Simple data model for history items (you can move this to /models later)
class MoodEntry {
  final DateTime date;
  final String emoji;       // e.g., '😄'
  final String label;       // e.g., 'Awesome'
  final String? note;       // optional
  final int score;          // 1..5 used for simple analytics

  MoodEntry({
    required this.date,
    required this.emoji,
    required this.label,
    this.note,
    required this.score,
  });
}

/// ---- MOCK DATA (replace with real data later) ----
List<MoodEntry> sampleEntries() {
  final now = DateTime.now();
  // last 10 days
  return List.generate(10, (i) {
    final d = now.subtract(Duration(days: i));
    final moods = [
      ['😄','Awesome',5],
      ['🙂','Good',4],
      ['😐','Neutral',3],
      ['🙁','Okay',2],
      ['😢','Sad',1],
    ];
    final m = moods[i % moods.length];
    return MoodEntry(
      date: d,
      emoji: m[0] as String,
      label: m[1] as String,
      score: m[2] as int,
      note: i.isEven ? 'Quick note for ${d.month}/${d.day}' : null,
    );
  }).reversed.toList();
}

/// ---- HISTORY / ANALYTICS SCREEN ----
/// Uses a single ListView so the entire screen scrolls
class MoodHistoryScreen extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodHistoryScreen({
    super.key,
    this.entries = const [],
  });

  List<MoodEntry> _effectiveEntries() {
    if (entries.isNotEmpty) return entries;
    return sampleEntries(); // use sample until you pass real data
  }

  @override
  Widget build(BuildContext context) {
    final data = _effectiveEntries();

    // Aggregate for last 7 days chart
    final today = DateTime.now();
    final last7 = List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      final sameDay = data.where((e) =>
      e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);
      // average score (1..5), or 0 if no entry that day
      final avg = sameDay.isEmpty
          ? 0.0
          : sameDay.map((e) => e.score).reduce((a, b) => a + b) /
          sameDay.length;
      return _DayPoint(day: day, average: avg);
    });

    final avgAll = data.isEmpty
        ? 0.0
        : data.map((e) => e.score).reduce((a, b) => a + b) / data.length;

    final thisWeekCount = data
        .where((e) => e.date.isAfter(
      DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 7)),
    ))
        .length;

    final streak = _streakDays(data);

    // We'll build a single ListView with:
    // 0: KPI Row
    // 1: 7-day chart
    // 2: "Recent Entries" header
    // 3..: each entry row
    final headerCount = 3;
    final totalItems = headerCount + data.length;

    return Scaffold(
      backgroundColor: const Color(0xFF2D7AF8), // primary blue to match app
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mood History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index == 0) {
              // KPI Row
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Avg Mood',
                          value: avgAll == 0 ? '—' : avgAll.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          title: 'This Week',
                          value: thisWeekCount.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          title: 'Streak',
                          value: '${streak}d',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            } else if (index == 1) {
              // 7-day Bar Chart
              return Column(
                children: [
                  _SevenDayChart(points: last7),
                  const SizedBox(height: 16),
                ],
              );
            } else if (index == 2) {
              // List header
              return const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Entries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            } else {
              // Entries
              final dataIndex = index - headerCount;
              final e = data[dataIndex];
              final dateStr =
                  '${_mm(e.date.month)}/${_mm(e.date.day)}/${e.date.year}';

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child:
                      Text(e.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(
                      '${e.label} • $dateStr',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: e.note == null
                        ? null
                        : Text(
                      e.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: _ScorePill(score: e.score),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // compute simple consecutive-day streak (days with >=1 entry)
  int _streakDays(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    // normalize to unique days
    final days = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort();
    int streak = 0;
    DateTime? prev;
    for (final d in days.reversed) {
      if (prev == null) {
        if (_isSameDay(d, DateTime.now()) || d.isBefore(DateTime.now())) {
          streak = 1;
          prev = d;
        }
      } else {
        if (prev!.difference(d).inDays == 1) {
          streak++;
          prev = d;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _mm(int n) => n < 10 ? '0$n' : '$n';
}

/// ----- Small KPI card
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  const _KpiCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

/// ----- seven-day bar chart (no external packages)
class _SevenDayChart extends StatelessWidget {
  final List<_DayPoint> points;
  const _SevenDayChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxVal = 5.0; // our score scale is 1..5
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final hFactor = (p.average / maxVal).clamp(0.0, 1.0);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // bar
                Flexible(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 18,
                      height: 120 * hFactor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _weekdayShort(p.day.weekday),
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _weekdayShort(int w) {
    const m = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return m[w]!;
  }
}

class _DayPoint {
  final DateTime day;
  final double average;
  _DayPoint({required this.day, required this.average});
}

/// Small pill to show score 1..5
class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score.toString(),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
