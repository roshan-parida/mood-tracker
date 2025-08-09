import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../models/mood_entry.dart';
import 'mood_entry_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _moodService = MoodService();

  final Map<String, String> moodEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Angry': '😠',
    'Excited': '🤩',
    'Calm': '😌',
    'Anxious': '😰',
    'Tired': '😴',
    'Neutral': '😐',
  };

  final Map<String, Color> moodColors = {
    'Happy': Colors.yellow.shade100,
    'Sad': Colors.blue.shade100,
    'Angry': Colors.red.shade100,
    'Excited': Colors.orange.shade100,
    'Calm': Colors.green.shade100,
    'Anxious': Colors.purple.shade100,
    'Tired': Colors.grey.shade300,
    'Neutral': Colors.teal.shade100,
  };

  late Future<List<MoodEntry>> _moodHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  void _loadMoodHistory() {
    _moodHistoryFuture = _moodService.getMoodHistory();
  }

  void _showEditNoteDialog(MoodEntry entry) {
    final controller = TextEditingController(text: entry.note ?? '');
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Edit Note"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Note',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _moodService.updateNoteForDate(
                  entry.timestamp,
                  controller.text.trim(),
                );
                Navigator.pop(context);
                setState(() {
                  _loadMoodHistory();
                });
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async => await _authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: Text("Log Today's Mood"),
                    onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MoodEntryScreen(moodEmojis: moodEmojis),
                          ),
                        ).then((_) {
                          setState(() {
                            _loadMoodHistory();
                          });
                        }),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    child: Text("View Mood Insights"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InsightsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<MoodEntry>>(
              future: _moodHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load mood history'));
                }
                final moods = snapshot.data;
                if (moods == null || moods.isEmpty) {
                  return Center(child: Text('No mood logs yet'));
                }
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: moods.length,
                  itemBuilder: (context, index) {
                    final entry = moods[index];
                    final formattedDate = DateFormat(
                      'EEE, MMM d, yyyy',
                    ).format(entry.timestamp);
                    final emoji = moodEmojis[entry.mood] ?? '';
                    return Card(
                      color: moodColors[entry.mood] ?? Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          '$emoji ${entry.mood}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.note != null && entry.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(entry.note!),
                              ),
                            SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey[700]),
                          onPressed: () {
                            _showEditNoteDialog(entry);
                          },
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
