class MoodModel {
  final String id;
  final String userId;
  final String moodEmoji;
  final String moodLabel;
  final String? note;           // Add if missing
  final String? noteEmoji;      // Add if missing
  final DateTime timestamp;

  MoodModel({
    required this.id,
    required this.userId,
    required this.moodEmoji,
    required this.moodLabel,
    this.note,
    this.noteEmoji,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'moodEmoji': moodEmoji,
      'moodLabel': moodLabel,
      'note': note,
      'noteEmoji': noteEmoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      id: map['id'],
      userId: map['userId'],
      moodEmoji: map['moodEmoji'],
      moodLabel: map['moodLabel'],
      note: map['note'],
      noteEmoji: map['noteEmoji'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}