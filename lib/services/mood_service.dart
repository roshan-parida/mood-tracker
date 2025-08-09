import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/mood_entry.dart';

class MoodService {
  static final MoodService _instance = MoodService._internal();
  factory MoodService() => _instance;
  MoodService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, List<MoodEntry>> _moodCache = {};
  DateTime? _lastCacheUpdate;

  Future<MoodResult> logMood(String mood, String? note) async {
    try {
      final uid = _getCurrentUserId();
      if (uid == null) {
        return MoodResult.failure('Please sign in to log your mood');
      }

      final today = DateTime.now();
      final docId = _formatDateId(today);

      final moodRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(docId);

      final doc = await moodRef.get();
      if (doc.exists) {
        return MoodResult.failure('You\'ve already logged your mood today!');
      }

      final moodEntry = MoodEntry(mood: mood, note: note, timestamp: today);

      await moodRef.set(moodEntry.toMap());
      _invalidateCache(uid);

      return MoodResult.success('Mood logged successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.message}');
      return MoodResult.failure('Failed to save mood. Please try again.');
    } catch (e) {
      debugPrint('Unexpected error in logMood: $e');
      return MoodResult.failure('An unexpected error occurred');
    }
  }

  Future<MoodResult> updateNoteForDate(DateTime date, String note) async {
    try {
      final uid = _getCurrentUserId();
      if (uid == null) {
        return MoodResult.failure('Please sign in to update notes');
      }

      final docId = _formatDateId(date);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(docId)
          .update({
            'note': note,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _invalidateCache(uid);
      return MoodResult.success('Note updated successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.message}');
      return MoodResult.failure('Failed to update note. Please try again.');
    } catch (e) {
      debugPrint('Unexpected error in updateNoteForDate: $e');
      return MoodResult.failure('An unexpected error occurred');
    }
  }

  Future<MoodResult> deleteMoodForDate(DateTime date) async {
    try {
      final uid = _getCurrentUserId();
      if (uid == null) {
        return MoodResult.failure('Please sign in to delete moods');
      }

      final docId = _formatDateId(date);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(docId)
          .delete();

      _invalidateCache(uid);
      return MoodResult.success('Mood entry deleted successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.message}');
      return MoodResult.failure('Failed to delete mood. Please try again.');
    } catch (e) {
      debugPrint('Unexpected error in deleteMoodForDate: $e');
      return MoodResult.failure('An unexpected error occurred');
    }
  }

  Future<List<MoodEntry>> getMoodHistory({int days = 30}) async {
    final uid = _getCurrentUserId();
    if (uid == null) return [];

    final cacheKey = '${uid}_$days';

    if (_moodCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _moodCache[cacheKey]!;
    }

    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final entries = snapshot.docs
          .map((doc) => MoodEntry.fromMap(doc.data()))
          .where((entry) => entry.timestamp.isAfter(cutoff))
          .toList();

      _moodCache[cacheKey] = entries;
      _lastCacheUpdate = DateTime.now();

      return entries;
    } catch (e) {
      debugPrint('Error fetching mood history: $e');
      return _moodCache[cacheKey] ?? [];
    }
  }

  Future<MoodStats> getMoodStats({int days = 30}) async {
    final moods = await getMoodHistory(days: days);

    if (moods.isEmpty) {
      return MoodStats(
        totalEntries: 0,
        mostFrequentMood: null,
        happyPercentage: 0,
        longestStreak: 0,
        moodDistribution: {},
      );
    }

    final Map<String, int> distribution = {};
    for (final mood in moods) {
      distribution[mood.mood] = (distribution[mood.mood] ?? 0) + 1;
    }

    final mostFrequent = distribution.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final happyMoods = ['Happy', 'Excited', 'Calm'];
    final happyCount = moods.where((m) => happyMoods.contains(m.mood)).length;
    final happyPercentage = (happyCount / moods.length) * 100;

    final sortedMoods = List<MoodEntry>.from(moods)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedMoods.length; i++) {
      if (sortedMoods[i].mood == sortedMoods[i - 1].mood) {
        currentStreak++;
      } else {
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
        currentStreak = 1;
      }
    }
    maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;

    return MoodStats(
      totalEntries: moods.length,
      mostFrequentMood: mostFrequent,
      happyPercentage: happyPercentage,
      longestStreak: maxStreak,
      moodDistribution: distribution,
    );
  }

  Future<bool> isMoodLoggedToday() async {
    final uid = _getCurrentUserId();
    if (uid == null) return false;

    try {
      final docId = _formatDateId(DateTime.now());
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(docId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking today\'s mood: $e');
      return false;
    }
  }

  Future<MoodEntry?> getMoodForDate(DateTime date) async {
    final uid = _getCurrentUserId();
    if (uid == null) return null;

    try {
      final docId = _formatDateId(date);
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(docId)
          .get();

      if (!doc.exists) return null;
      return MoodEntry.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching mood for date: $e');
      return null;
    }
  }

  String? _getCurrentUserId() => _auth.currentUser?.uid;

  String _formatDateId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _invalidateCache(String uid) {
    _moodCache.removeWhere((key, _) => key.startsWith(uid));
    _lastCacheUpdate = null;
  }
}

class MoodResult {
  final bool isSuccess;
  final String message;

  MoodResult._({required this.isSuccess, required this.message});

  factory MoodResult.success(String message) {
    return MoodResult._(isSuccess: true, message: message);
  }

  factory MoodResult.failure(String message) {
    return MoodResult._(isSuccess: false, message: message);
  }
}

class MoodStats {
  final int totalEntries;
  final String? mostFrequentMood;
  final double happyPercentage;
  final int longestStreak;
  final Map<String, int> moodDistribution;

  MoodStats({
    required this.totalEntries,
    required this.mostFrequentMood,
    required this.happyPercentage,
    required this.longestStreak,
    required this.moodDistribution,
  });
}
