// File: lib/views/achievements/badges_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/badge_model.dart';

// Helper class: Defines the static data (text & icons) for every possible achievement.
// Unlike the Hive model (which tracks user progress), this just holds the UI definitions.
class _AchievementData {
  final String title;
  final String subtitle;
  final IconData icon;

  _AchievementData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Box<BadgeModel> badgesBox;

  // UI Theme: The app's primary orange color (#FF6B4A) used for unlocked badges.
  static const Color _brandColor = Color(0xFFFF6B4A);

  // Data Source: A hardcoded list of all 6 achievable badges and their descriptions.
  final List<_AchievementData> _allAchievements = [
    _AchievementData(
      title: 'First Skill Added',
      subtitle: 'Added your first skill',
      icon: Icons.gps_fixed, // Target icon
    ),
    _AchievementData(
      title: 'First Skill Completed',
      subtitle: 'Completed your first skill',
      icon: Icons.check_circle_outline,
    ),
    _AchievementData(
      title: '5 Notes Created',
      subtitle: 'Created 5 learning notes',
      icon: Icons.note_add_outlined,
    ),
    _AchievementData(
      title: '10 Skills Added',
      subtitle: 'Added 10 skills to track',
      icon: Icons.list_alt_outlined,
    ),
    _AchievementData(
      title: 'Weekly Streak',
      subtitle: 'Logged notes for 7 consecutive days',
      icon: Icons.local_fire_department_outlined,
    ),
    _AchievementData(
      title: 'Overachiever',
      subtitle: 'Completed 5 skills',
      icon: Icons.star_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Database Logic: Opens the specific badge box linked to the current user's email.
    // This ensures one user doesn't see another user's badges.
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    badgesBox = Hive.box<BadgeModel>('badgesBox_$sanitizedEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // State Management: Listens to the Badge Box.
      // If a new badge is awarded elsewhere, this screen updates immediately.
      body: ValueListenableBuilder(
        valueListenable: badgesBox.listenable(),
        builder: (context, Box<BadgeModel> box, _) {
          // Logic: Gets the list of badges the user has actually earned from the DB.
          final earnedBadges = box.values.toList();
          final earnedBadgeMap = {for (var b in earnedBadges) b.title: b};
          final int earnedCount = earnedBadgeMap.length;
          final int totalCount = _allAchievements.length;

          // [MODIFIED] Replaced SingleChildScrollView with a Column
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UI Component: The top header with Back Button and Progress Bar (e.g., 3/6)
              _buildSimpleHeader(context, earnedCount, totalCount),

              // [MODIFIED] Added Expanded to make the GridView scrollable
              // UI Component: The scrollable grid containing the badge cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 Cards per row
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _allAchievements.length,
                    // [REMOVED] shrinkWrap: true
                    // [REMOVED] physics: const NeverScrollableScrollPhysics()
                    itemBuilder: (ctx, i) {
                      final achievement = _allAchievements[i];
                      // Logic: Checks if the current card corresponds to an earned badge
                      final BadgeModel? earnedBadge =
                      earnedBadgeMap[achievement.title];

                      // UI Component: Renders individual badge card (Locked or Unlocked)
                      return _buildBadgeCard(achievement, earnedBadge);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// UI Component: Builds the top header section.
  /// Contains: Back Icon, "Achievements" Title, and Linear Progress Bar.
  Widget _buildSimpleHeader(
      BuildContext context, int earnedCount, int totalCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button logic: Returns to Profile Screen
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 8),
            // Title Text
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Progress Bar Visual: Shows visually how close user is to 100% completion
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? earnedCount / totalCount : 0,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: _brandColor, // Orange fill for progress
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Counter: e.g., "3/6"
                  Text(
                    '$earnedCount/$totalCount',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// UI Component: Builds a single Badge Card.
  /// Logic: Determines styling based on 'isEarned'.
  /// If Earned: Shows orange icon and "Earned!" checkmark.
  /// If Locked: Shows grey lock icon and grey text.
  Widget _buildBadgeCard(
      _AchievementData achievement, BadgeModel? earnedBadge) {
    final bool isEarned = earnedBadge != null;
    final Color color = isEarned ? _brandColor : Colors.grey[400]!;
    final IconData icon = isEarned ? achievement.icon : Icons.lock_outline;

    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withAlpha(13), // 0.05 opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Circle
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withAlpha(26), // Light background circle
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            // Badge Title
            Text(
              achievement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Badge Subtitle/Description
            Text(
              achievement.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            // Logic: Only show "Earned!" text if the user actually has the badge
            if (isEarned)
              Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Earned!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 16), // Placeholder to keep height consistent
          ],
        ),
      ),
    );
  }
}