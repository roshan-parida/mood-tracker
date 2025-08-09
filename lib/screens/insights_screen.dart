import 'package:flutter/material.dart';

import '../services/mood_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final MoodService _moodService = MoodService();

  String? _mostFrequentMood;
  double? _happyPercentage;
  int? _longestStreak;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final mostFrequent = await _moodService.getMostFrequentMood();
      final happyPercent = await _moodService.getHappyPercentage();
      final longestStreak = await _moodService.getLongestStreak();

      setState(() {
        _mostFrequentMood = mostFrequent ?? 'No data';
        _happyPercentage = happyPercent;
        _longestStreak = longestStreak;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load insights';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood Insights')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Frequent Mood (Last 7 days):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _mostFrequentMood ?? 'N/A',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Percentage of "Happy" Days:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_happyPercentage?.toStringAsFixed(1) ?? '0.0'}%',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Longest Streak of Same Mood:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_longestStreak ?? 0} days',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
