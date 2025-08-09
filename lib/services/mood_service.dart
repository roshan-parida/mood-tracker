import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mood_entry.dart';

class MoodService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> logMood(String mood, String? note) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final today = DateTime.now();
    final docId =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final moodRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(docId);
    final doc = await moodRef.get();

    if (doc.exists) {
      throw Exception("Mood already logged for today.");
    }

    await moodRef.set({
      'mood': mood,
      'note': note,
      'timestamp': Timestamp.fromDate(today),
    });
  }

  Future<void> updateNoteForDate(DateTime date, String note) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final docId =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(docId)
        .update({'note': note});
  }

  Future<List<MoodEntry>> getMoodHistory({int days = 7}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .get();

    final List<MoodEntry> entries = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final ts = data['timestamp'];
      DateTime entryDate;
      if (ts is Timestamp) {
        entryDate = ts.toDate();
      } else if (ts is String) {
        entryDate = DateTime.parse(ts);
      } else {
        continue;
      }
      if (entryDate.isAfter(cutoff)) {
        entries.add(MoodEntry.fromMap(data));
      }
    }
    return entries;
  }

  Future<String?> getMostFrequentMood({int days = 7}) async {
    final moods = await getMoodHistory(days: days);
    if (moods.isEmpty) return null;

    final Map<String, int> freq = {};
    for (var m in moods) {
      freq[m.mood] = (freq[m.mood] ?? 0) + 1;
    }

    String mostFrequent = freq.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return mostFrequent;
  }

  Future<double> getHappyPercentage({int days = 7}) async {
    final moods = await getMoodHistory(days: days);
    if (moods.isEmpty) return 0;

    int happyCount = moods.where((m) => m.mood == 'Happy').length;
    return (happyCount / moods.length) * 100;
  }

  Future<int> getLongestStreak({int days = 7}) async {
    final moods = await getMoodHistory(days: days);
    if (moods.isEmpty) return 0;

    // Sort oldest to newest
    moods.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < moods.length; i++) {
      if (moods[i].mood == moods[i - 1].mood) {
        currentStreak++;
      } else {
        if (currentStreak > maxStreak) maxStreak = currentStreak;
        currentStreak = 1;
      }
    }
    if (currentStreak > maxStreak) maxStreak = currentStreak;
    return maxStreak;
  }
}
