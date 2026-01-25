// File: lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math; // Used for calculating angles in the circular progress bar
import '../../models/skill_model.dart';

class HomeScreen extends StatefulWidget {
  // Logic: A 'Callback' is a function passed from a parent widget.
  // Here, the parent (Main Shell) tells Home Screen what to do when "See All" is tapped.
  // This helps switch tabs programmatically.
  final VoidCallback onSeeAllTapped;

  const HomeScreen({
    super.key,
    required this.onSeeAllTapped, // Required to ensure navigation works
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

    // Logic: Database Setup.
    // 1. Get the current user's email.
    // 2. Open their specific Skills Box.
    // 3. Retrieve their actual name to display in the greeting "Hi, [Name]".
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');

    // Logic: Name Retrieval
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
      // State Management: ValueListenableBuilder listens to the database.
      // Whenever a skill is added/edited anywhere, this builder rebuilds the UI instantly.
      child: ValueListenableBuilder<Box<SkillModel>>(
        valueListenable: skillsBox.listenable(),
        builder: (context, box, _) {
          final allSkills = box.values.toList().cast<SkillModel>();
          // Logic: Filter out completed skills (100%) so Home only shows active tasks.
          final activeSkills = allSkills.where((s) => s.progress < 100).toList();

          // Logic: Calculate average progress for the top "Weekly Progress" card.
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
                // UI Component: "Hi, Name" greeting
                _buildHeader(primaryColor, userName),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // UI Component: The large top card with circular progress
                      _buildWeeklyProgressCard(primaryColor, avgProgress.toInt()),
                      const SizedBox(height: 24),

                      // UI Component: "Active Skills" Header + "See All" button
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
                            // Logic: Triggers the callback to switch to the "Library" tab
                            onPressed: widget.onSeeAllTapped,
                            child: const Text('See all',
                                style: TextStyle(color: primaryColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Logic: Conditional Rendering
                      // 1. No skills at all? Show "Empty State" (Add your first skill).
                      // 2. All skills 100%? Show "All Completed State" (Great job!).
                      // 3. Otherwise, show the list of active skill cards.
                      if (allSkills.isEmpty)
                        _buildEmptyState(primaryColor)
                      else if (activeSkills.isEmpty)
                        _buildAllCompletedState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          // Disable scrolling here so the parent SingleChildScrollView handles it
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
                const SizedBox(height: 80), // Extra space at bottom for scrolling
              ],
            ),
          );
        },
      ),
    );
  }

  // UI Component: Header section with Name and Subtext
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

  // UI Component: Top Card showing "Weekly Progress" with Circle Graph
  Widget _buildWeeklyProgressCard(Color primaryColor, int averageProgress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F4), // Light Orange Background
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
          // Custom Widget: The Circular Progress Indicator
          _LiveCircularProgress(
            progressPercent: averageProgress,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  // UI Component: Shown when user has 0 skills in database
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

  // UI Component: Shown when all skills are 100% complete
  Widget _buildAllCompletedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50], // Light Green Background
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

  // UI Component: Individual Skill Card in the list
  Widget _buildSkillCard(SkillModel skill, Color primaryColor) {
    // Helper: Selects icon based on skill category
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

    // Logic: Tapping the card navigates to Detail Screen
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
            // Icon Circle
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withAlpha(26),
              foregroundColor: primaryColor,
              child: Icon(getCategoryIcon(skill.category)),
            ),
            const SizedBox(width: 16),
            // Skill Name and Category Text
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
            // Progress Percent and Linear Bar
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

// Custom Widget: Draws the Circular Progress Indicator using CustomPaint
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
          // Background Circle (Light Orange)
          CustomPaint(
            size: const Size(70, 70),
            painter: _ProgressArcPainter(
              percent: 1.0,
              color: primaryColor.withAlpha(51),
              strokeWidth: 8,
            ),
          ),
          // Foreground Arc (Dark Orange) - Based on actual progress
          CustomPaint(
            size: const Size(70, 70),
            painter: _ProgressArcPainter(
              percent: progressPercent / 100,
              color: primaryColor,
              strokeWidth: 8,
            ),
          ),
          // Centered Percentage Text
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

// Canvas Painter: Low-level drawing code for the circular arc
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

    const startAngle = -math.pi / 2; // Starts from top (12 o'clock)
    final sweepAngle = percent * 2 * math.pi; // Calculates arc length

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return percent != oldDelegate.percent;
  }
}