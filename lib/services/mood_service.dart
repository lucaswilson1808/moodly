import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_model.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Save a new mood entry
  Future<String> saveMoodEntry({
    required String moodEmoji,
    required String moodLabel,
    String? note,
    String? noteEmoji,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final docRef = _firestore.collection('mood_entries').doc();

      final entry = MoodModel(
        id: docRef.id,
        userId: userId,
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        note: note,
        noteEmoji: noteEmoji,
        timestamp: DateTime.now(),
      );

      await docRef.set(entry.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save mood entry: $e');
    }
  }

  // Update existing entry with note
  Future<void> addNoteToEntry(String entryId, String note, String noteEmoji) async {
    try {
      await _firestore.collection('mood_entries').doc(entryId).update({
        'note': note,
        'noteEmoji': noteEmoji,
      });
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // Get all mood entries for current user
  Future<List<MoodModel>> getMoodEntries() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MoodModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get mood entries: $e');
    }
  }

  // Get mood entries for a date range (for calendar/charts)
  Future<List<MoodModel>> getMoodsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MoodModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get moods by date range: $e');
    }
  }

  // Delete mood entry
  Future<void> deleteMoodEntry(String entryId) async {
    try {
      await _firestore.collection('mood_entries').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete mood entry: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<MoodModel>> moodEntriesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('mood_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MoodModel.fromMap(doc.data()))
        .toList());
  }
}