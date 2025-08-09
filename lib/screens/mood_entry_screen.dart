import 'package:flutter/material.dart';

import '../services/mood_service.dart';

class MoodEntryScreen extends StatefulWidget {
  final Map<String, String> moodEmojis;

  const MoodEntryScreen({super.key, required this.moodEmojis});

  @override
  _MoodEntryScreenState createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends State<MoodEntryScreen> {
  String? selectedMood;
  final _noteController = TextEditingController();
  final _moodService = MoodService();
  bool _isSubmitting = false;

  void _submitMood() async {
    if (selectedMood == null) return;
    setState(() => _isSubmitting = true);

    try {
      await _moodService.logMood(selectedMood!, _noteController.text);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log Mood")),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How are you feeling today?", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMood,
              items: widget.moodEmojis.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text('${entry.value} ${entry.key}'),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Mood',
              ),
              onChanged: (value) => setState(() => selectedMood = value),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Optional Note",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMood,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Submit Mood"),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
