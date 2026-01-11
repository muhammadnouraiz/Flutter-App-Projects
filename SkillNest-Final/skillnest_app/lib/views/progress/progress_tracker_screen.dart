import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
  }

  // --- HELPER METHODS ---
  List<double> _calculateWeeklyActivity() {
    List<double> weeklyData = List.filled(7, 0.0);
    final allNotes = notesBox.values;
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    final mostRecentMonday = DateTime(now.year, now.month, now.day - daysSinceMonday);
    final endOfWeek = mostRecentMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final thisWeekNotes = allNotes.where((note) {
      return note.createdAt.isAfter(mostRecentMonday) &&
          note.createdAt.isBefore(endOfWeek);
    });

    for (final note in thisWeekNotes) {
      final weekdayIndex = note.createdAt.weekday - 1;
      weeklyData[weekdayIndex]++;
    }
    return weeklyData;
  }

  List<BarChartGroupData> _buildBarChartGroups(List<double> weeklyData) {
    const gradient = LinearGradient(
      colors: [Color(0xFFFF6B4A), Color(0xFFFF9A8B)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
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

  // [FIXED] Updated for fl_chart 0.65.0 compatibility
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
    // [FIXED] Removed 'axisSide' parameter which caused the error
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }

  // [FIXED] Updated for fl_chart 0.65.0 compatibility
  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) {
      return Container();
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
    // --- Data Calculations ---
    final skills = skillsBox.values.toList().cast<SkillModel>();
    final total = skills.length;
    final completed = skills.where((s) => s.progress >= 100).length;
    final ongoing = total - completed;

    double avgProgress = 0;
    if (total > 0) {
      avgProgress =
          skills.map((s) => s.progress).reduce((a, b) => a + b) / total;
    }

    SkillModel? mostImproved;
    if (skills.isNotEmpty) {
      final sortedSkills = List<SkillModel>.from(skills);
      sortedSkills.sort((a, b) => b.progress.compareTo(a.progress));
      mostImproved = sortedSkills.first;
    }

    final List<double> weeklyActivityData = _calculateWeeklyActivity();
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
                  _buildSectionTitle('Weekly Activity'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2.0,
                    shadowColor: Colors.black.withAlpha(13),
                    color: const Color(0xFFFFEEEB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 8.0, bottom: 8.0),
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
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          // [FIXED] Updated Tooltip logic for 0.65.0
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.transparent, // Reverted name
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 4,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toStringAsFixed(0), // No decimal places for count
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