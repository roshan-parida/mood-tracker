import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String mood;
  final String? note;
  final DateTime timestamp;

  MoodEntry({required this.mood, this.note, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    DateTime parsedTime;

    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return MoodEntry(
      mood: map['mood'] ?? '',
      note: map['note'],
      timestamp: parsedTime,
    );
  }
}
