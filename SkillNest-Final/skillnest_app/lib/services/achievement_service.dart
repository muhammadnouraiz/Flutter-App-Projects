// File: lib/services/achievement_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/skill_model.dart';
import '../models/note_model.dart';

// Service Class: Handles the logic for checking and awarding achievements.
// It bridges the Database (Hive) and the UI (Snackbars/Badge Screen).
class AchievementService {

  // UI Functionality: Displays the green "Snackbar" popup at the bottom of the screen
  // telling the user they unlocked a badge (e.g., "🏆 Achievement Unlocked!").
  static void _showBadgeUnlock(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('🏆 Achievement Unlocked: $title!'),
      ),
    );
  }

  /// Logic: Prevents duplicate badges. It checks if the badge title already exists
  /// in the database before awarding it.
  static Future<void> _awardBadge(
      Box<BadgeModel> badgesBox, String title, BuildContext context) async {
    // Check if a badge with this TITLE already exists
    bool alreadyEarned = badgesBox.values.any((b) => b.title == title);

    if (!alreadyEarned) {
      final newBadge = BadgeModel(
        title: title,
        earned: true, // Sets the badge status to "Unlocked" (Full color in UI)
        iconPath: null, // The badges_screen will handle the icon
      );

      await badgesBox.add(newBadge); // Save to Hive Database

      // Check if context is still valid before showing SnackBar
      if (context.mounted) {
        _showBadgeUnlock(context, newBadge.title);
      }
    }
  }

  // --- CHECK FUNCTIONS ---

  /// Trigger: Called immediately after the user taps "Add Skill" on the Add Skill Screen.
  /// UI Impact: Unlocks "First Skill Added" or "10 Skills Added" cards in Profile > Badges.
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

  /// Trigger: Called after the user saves a note in "Add Note Screen".
  /// UI Impact: Unlocks "5 Notes Created" badge in the Profile Screen.
  static Future<void> checkNoteAddedBadges(
      Box<NoteModel> notesBox, Box<BadgeModel> badgesBox, BuildContext context) async {

    // [FIXED] Changed from == 5 to >= 5
    if (notesBox.length >= 5) {
      await _awardBadge(badgesBox, '5 Notes Created', context);
    }

    // TODO: Add 'Weekly Streak' logic here.
  }

  /// Trigger: Called whenever progress is updated (Add Note or Edit Skill).
  /// UI Impact: Unlocks "First Skill Completed" (100%) or "Overachiever" badges.
  static Future<void> checkSkillCompletedBadges(
      Box<SkillModel> skillsBox, Box<BadgeModel> badgesBox, BuildContext context) async {

    // Logic: Filters skills that have reached 100% progress
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