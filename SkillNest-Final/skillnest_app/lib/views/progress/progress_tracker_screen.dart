// File: lib/views/progress/progress_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // Charting Library
import '../../models/skill_model.dart';
import '../../models/note_model.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({Key? key}) : super(key: key);
  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  late Box<SkillModel> skillsBox;
  late Box<NoteModel> notesBox;

  @override
  void initState() {
    super.initState();
    // Logic: Database Setup.
    // Opens both 'skillsBox' (for totals/progress) and 'notesBox' (for activity chart).
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
  }

  // --- HELPER METHODS ---

  /// 📊 Logic: Weekly Activity Calculation.
  /// 1. Determines the date range for the current week (Monday to Sunday).
  /// 2. Filters all notes to find only those created within this range.
  /// 3. Maps them to an array of 7 doubles (Mon=0, Tue=1, etc.) representing note counts per day.
  List<double> _calculateWeeklyActivity() {
    List<double> weeklyData = List.filled(7, 0.0);
    final allNotes = notesBox.values;
    final now = DateTime.now();

    // Find last Monday
    final daysSinceMonday = now.weekday - 1;
    final mostRecentMonday = DateTime(now.year, now.month, now.day - daysSinceMonday);
    final endOfWeek = mostRecentMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // Filter notes
    final thisWeekNotes = allNotes.where((note) {
      return note.createdAt.isAfter(mostRecentMonday) &&
          note.createdAt.isBefore(endOfWeek);
    });

    // Populate array
    for (final note in thisWeekNotes) {
      final weekdayIndex = note.createdAt.weekday - 1;
      weeklyData[weekdayIndex]++;
    }
    return weeklyData;
  }

  /// 📊 UI: Bar Chart Config.
  /// Configures the visual look of the bars (Orange Gradient, Rounded Corners).
  List<BarChartGroupData> _buildBarChartGroups(List<double> weeklyData) {
    const gradient = LinearGradient(
      colors: [Color(0xFFFF6B4A), Color(0xFFFF9A8B)], // Orange Gradient
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        // Shows number on top if value > 0
        showingTooltipIndicators: weeklyData[i] > 0 ? [0] : [],
        barRods: [
          BarChartRodData(
            toY: weeklyData[i],
            gradient: gradient,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  // UI Helper: Bottom Axis Labels (Mon, Tue, Wed...)
  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Mon'; break;
      case 1: text = 'Tue'; break;
      case 2: text = 'Wed'; break;
      case 3: text = 'Thu'; break;
      case 4: text = 'Fri'; break;
      case 5: text = 'Sat'; break;
      case 6: text = 'Sun'; break;
      default: return Container();
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }

  // UI Helper: Left Axis Labels (0, 5, 10...)
  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) {
      return Container(); // Hide min/max to prevent clipping
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  // UI Component: Screen Header
  Widget _buildSimpleHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Tracker',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your learning journey',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // UI Component: The 4 Grid Cards (Total Skills, Completed, In Progress, Avg Progress)
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withAlpha(13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFF6B4A), size: 30),
            const SizedBox(height: 12),
            Text(title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Component: "Most Improved" Card at the bottom
  Widget _buildMostImprovedCard(SkillModel skill) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withAlpha(13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Great progress this week!',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            Text(
              '${skill.progress}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B4A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Logic: Data Calculations ---
    final skills = skillsBox.values.toList().cast<SkillModel>();
    final total = skills.length;
    final completed = skills.where((s) => s.progress >= 100).length;
    final ongoing = total - completed;

    // Logic: Calculate Average Progress across all skills
    double avgProgress = 0;
    if (total > 0) {
      avgProgress =
          skills.map((s) => s.progress).reduce((a, b) => a + b) / total;
    }

    // Logic: Find Most Improved (Currently just picking highest progress for demo)
    SkillModel? mostImproved;
    if (skills.isNotEmpty) {
      final sortedSkills = List<SkillModel>.from(skills);
      sortedSkills.sort((a, b) => b.progress.compareTo(a.progress));
      mostImproved = sortedSkills.first;
    }

    // Logic: Chart Data Prep
    final List<double> weeklyActivityData = _calculateWeeklyActivity();
    // Dynamically set Y-Axis Max Height so chart looks good
    double maxActivity = weeklyActivityData.isEmpty
        ? 5
        : weeklyActivityData.reduce((a, b) => a > b ? a : b) + 5;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UI: The 4 Statistics Cards arranged in 2 Rows
                  Row(children: [
                    Expanded(child: _buildInfoCard('Total Skills', total.toString(), Icons.book_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCard('Completed', completed.toString(), Icons.task_alt_outlined)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _buildInfoCard('In Progress', ongoing.toString(), Icons.schedule_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCard('Avg Progress', '${avgProgress.toStringAsFixed(0)}%', Icons.trending_up)),
                  ]),

                  const SizedBox(height: 24),

                  // UI: Weekly Activity Chart Section
                  _buildSectionTitle('Weekly Activity'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2.0,
                    shadowColor: Colors.black.withAlpha(13),
                    color: const Color(0xFFFFEEEB), // Light Pink background for Chart
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 8.0, bottom: 8.0),
                      // The Chart Widget from fl_chart package
                      child: BarChart(
                        BarChartData(
                          maxY: maxActivity,
                          minY: 0,
                          barGroups: _buildBarChartGroups(weeklyActivityData),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: _getLeftTitles,
                                reservedSize: 28,
                                interval: (maxActivity / 5).floor().toDouble() > 0 ? (maxActivity / 5).floor().toDouble() : 1,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: _getBottomTitles,
                                reservedSize: 30,
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: false), // Hide grid lines
                          borderData: FlBorderData(show: false), // Hide border box
                          // Tooltip Config: Shows number when bar is touched or by default
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.transparent,
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 4,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toStringAsFixed(0),
                                  const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // UI: Most Improved Card (Optional)
                  if (mostImproved != null) ...[
                    _buildSectionTitle('Most Improved'),
                    const SizedBox(height: 12),
                    _buildMostImprovedCard(mostImproved),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}