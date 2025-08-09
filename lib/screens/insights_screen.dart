import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/mood_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  final MoodService _moodService = MoodService();

  MoodStats? _moodStats;
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 30;

  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  final List<int> _dayOptions = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInsights();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _moodService.getMoodStats(days: _selectedDays);

      if (mounted) {
        setState(() {
          _moodStats = stats;
          _isLoading = false;
        });
        _animationController.forward();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load insights. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onDaysChanged(int days) {
    if (_selectedDays != days) {
      setState(() => _selectedDays = days);
      _animationController.reset();
      _loadInsights();
    }
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: _dayOptions.map((days) {
          final isSelected = _selectedDays == days;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: days != _dayOptions.last ? 8 : 0),
              child: FilterChip(
                label: Text(
                  days == 365 ? '1 Year' : '${days}d',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _onDaysChanged(days),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Colors.white,
                elevation: isSelected ? 2 : 0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Animation<double> animation,
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: color.withAlpha((0.1 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const Spacer(),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodDistributionChart() {
    if (_moodStats?.moodDistribution.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    final distribution = _moodStats!.moodDistribution;
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final moodColors = {
      'Happy': Colors.amber,
      'Excited': Colors.orange,
      'Joyful': Colors.yellow.shade700,
      'Grateful': Colors.green,
      'Content': Colors.blue,
      'Calm': Colors.teal,
      'Sad': Colors.indigo,
      'Anxious': Colors.purple,
      'Angry': Colors.red,
      'Stressed': Colors.deepOrange,
    };

    return AnimatedBuilder(
      animation: _cardAnimations[3],
      builder: (context, child) {
        return FadeTransition(
          opacity: _cardAnimations[3],
          child: ScaleTransition(
            scale: _cardAnimations[3],
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mood Distribution',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...sortedEntries.take(5).map((entry) {
                    final percentage =
                        (entry.value / _moodStats!.totalEntries * 100);
                    final color = moodColors[entry.key] ?? Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mood Insights'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    _animationController.reset();
                    _loadInsights();
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your mood patterns...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInsights,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _moodStats?.totalEntries == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mood_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No mood data yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start logging your moods to see insights',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildInsightCard(
                        title: 'Total Entries',
                        value: '${_moodStats?.totalEntries ?? 0}',
                        icon: Icons.calendar_today_outlined,
                        color: theme.colorScheme.primary,
                        animation: _cardAnimations[0],
                      ),
                      _buildInsightCard(
                        title: 'Most Frequent',
                        value: _moodStats?.mostFrequentMood ?? 'None',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        animation: _cardAnimations[1],
                      ),
                      _buildInsightCard(
                        title: 'Positive Moods',
                        value:
                            '${_moodStats?.happyPercentage.toStringAsFixed(1) ?? '0'}%',
                        icon: Icons.sentiment_satisfied_alt,
                        color: Colors.amber.shade600,
                        animation: _cardAnimations[2],
                      ),
                      _buildInsightCard(
                        title: 'Longest Streak',
                        value: '${_moodStats?.longestStreak ?? 0}',
                        icon: Icons.local_fire_department,
                        color: Colors.orange.shade600,
                        animation: _cardAnimations[3],
                        subtitle: 'days',
                      ),
                    ],
                  ),
                  _buildMoodDistributionChart(),
                ],
              ),
            ),
    );
  }
}
