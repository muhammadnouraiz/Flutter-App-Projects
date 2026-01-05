// File: lib/services/achievement_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/skill_model.dart';
import '../models/note_model.dart';

class AchievementService {
  // Helper to show a snackbar when a badge is unlocked
  static void _showBadgeUnlock(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('🏆 Achievement Unlocked: $title!'),
      ),
    );
  }

  /// Helper to check and add a badge.
  static Future<void> _awardBadge(
      Box<BadgeModel> badgesBox, String title, BuildContext context) async {
    // Check if a badge with this TITLE already exists
    bool alreadyEarned = badgesBox.values.any((b) => b.title == title);

    if (!alreadyEarned) {
      final newBadge = BadgeModel(
        title: title,
        earned: true,
        iconPath: null, // The badges_screen will handle the icon
      );

      await badgesBox.add(newBadge);

      // Check if context is still valid before showing SnackBar
      if (context.mounted) {
        _showBadgeUnlock(context, newBadge.title);
      }
    }
  }

  // --- CHECK FUNCTIONS ---

  /// Call this from AddSkillScreen
  static Future<void> checkSkillAddedBadges(
      Box<SkillModel> skillsBox, Box<BadgeModel> badgesBox, BuildContext context) async {

    // [FIXED] Changed from == 1 to >= 1
    if (skillsBox.length >= 1) {
      await _awardBadge(badgesBox, 'First Skill Added', context);
    }

    // [FIXED] Changed from == 10 to >= 10
    if (skillsBox.length >= 10) {
      await _awardBadge(badgesBox, '10 Skills Added', context);
    }
  }

  /// Call this from AddNoteScreen
  static Future<void> checkNoteAddedBadges(
      Box<NoteModel> notesBox, Box<BadgeModel> badgesBox, BuildContext context) async {

    // [FIXED] Changed from == 5 to >= 5
    if (notesBox.length >= 5) {
      await _awardBadge(badgesBox, '5 Notes Created', context);
    }

    // TODO: Add 'Weekly Streak' logic here.
  }

  /// Call this from AddNoteScreen or SkillDetailScreen
  static Future<void> checkSkillCompletedBadges(
      Box<SkillModel> skillsBox, Box<BadgeModel> badgesBox, BuildContext context) async {

    final completedSkills = skillsBox.values.where((s) => s.progress >= 100).toList();

    // [FIXED] Changed from == 1 to >= 1
    if (completedSkills.length >= 1) {
      await _awardBadge(badgesBox, 'First Skill Completed', context);
    }

    // [FIXED] Changed from == 5 to >= 5
    if (completedSkills.length >= 5) {
      await _awardBadge(badgesBox, 'Overachiever', context);
    }
  }
}