// File: lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math; // For custom painter
import '../../models/skill_model.dart';

class HomeScreen extends StatefulWidget {
  // [MODIFIED] Added the callback
  final VoidCallback onSeeAllTapped;

  const HomeScreen({
    super.key,
    required this.onSeeAllTapped, // Make it required
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<SkillModel> skillsBox;
  String userName = 'User';

  @override
  void initState() {
    super.initState();

    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');

    if (email == 'guest') {
      userName = 'Guest';
    } else {
      final dynamic rawMap = userBox.get('userNames', defaultValue: <String, String>{});
      if (rawMap is Map) {
        userName = Map<String, String>.from(rawMap)[email] ?? 'User';
      } else {
        userName = 'User';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF6B4A);

    return Container(
      color: Colors.white,
      child: ValueListenableBuilder<Box<SkillModel>>(
        valueListenable: skillsBox.listenable(),
        builder: (context, box, _) {
          final allSkills = box.values.toList().cast<SkillModel>();
          final activeSkills = allSkills.where((s) => s.progress < 100).toList();

          double avgProgress = 0.0;
          if (allSkills.isNotEmpty) {
            avgProgress = allSkills.map((s) => s.progress).reduce((a, b) => a + b) /
                allSkills.length;
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(primaryColor, userName),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildWeeklyProgressCard(primaryColor, avgProgress.toInt()),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Skills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            // [FIXED] Use the callback from the parent widget
                            onPressed: widget.onSeeAllTapped,
                            child: const Text('See all',
                                style: TextStyle(color: primaryColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (allSkills.isEmpty)
                        _buildEmptyState(primaryColor)
                      else if (activeSkills.isEmpty)
                        _buildAllCompletedState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeSkills.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final s = activeSkills[i];
                            return _buildSkillCard(s, primaryColor);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, String name) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $name',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'What\'d you like to learn today?',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(Color primaryColor, int averageProgress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re doing great work!\nKeep it up.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _LiveCircularProgress(
            progressPercent: averageProgress,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.add_task, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No skills yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new skill to start your journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, '/skill/add'),
            child: const Text('Add Your First Skill'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCompletedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: Colors.green[600]),
          const SizedBox(height: 16),
          const Text(
            'All Skills Completed!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great job! Add a new skill to keep growing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(SkillModel skill, Color primaryColor) {
    IconData getCategoryIcon(String category) {
      switch (category) {
        case 'Tech':
          return Icons.code;
        case 'Productivity':
          return Icons.auto_awesome;
        case 'Communication':
          return Icons.speaker_notes;
        case 'Design':
          return Icons.palette;
        default:
          return Icons.category;
      }
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/skill/detail', arguments: skill.key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withAlpha(26),
              foregroundColor: primaryColor,
              child: Icon(getCategoryIcon(skill.category)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${skill.category} • ${skill.deadline.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${skill.progress}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: (skill.progress / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: primaryColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCircularProgress extends StatelessWidget {
  const _LiveCircularProgress({
    required this.progressPercent,
    required this.primaryColor,
  });

  final int progressPercent;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(70, 70),
            painter: _ProgressArcPainter(
              percent: 1.0,
              color: primaryColor.withAlpha(51),
              strokeWidth: 8,
            ),
          ),
          CustomPaint(
            size: const Size(70, 70),
            painter: _ProgressArcPainter(
              percent: progressPercent / 100,
              color: primaryColor,
              strokeWidth: 8,
            ),
          ),
          Center(
            child: Text(
              '$progressPercent%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter({
    required this.percent,
    required this.color,
    required this.strokeWidth,
  });

  final double percent;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2;
    final sweepAngle = percent * 2 * math.pi;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return percent != oldDelegate.percent;
  }
}