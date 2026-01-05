// File: lib/views/notes/add_note_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/note_model.dart';
import '../../models/skill_model.dart';
// [+ NEW] Imports for achievement logic
import '../../models/badge_model.dart';
import '../../services/achievement_service.dart';

class AddNoteScreen extends StatefulWidget {
  // [FIXED] Use super.key
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _progress = TextEditingController();

  late Box<NoteModel> notesBox;
  late Box<SkillModel> skillsBox;
  // [+ NEW] Add box for badges
  late Box<BadgeModel> badgesBox;
  dynamic skillKey;
  SkillModel? skill;

  static const Color _brandColor = Color(0xFFFF6B4A);
  static const Color _lightPinkColor = Color(0xFFFFF6F4);
  static const Color _textFieldColor = Color(0xFFFDFDFD);
  static const Color _borderColor = Color(0xFFE0E0E0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    // [+ NEW] Open badges box
    badgesBox = Hive.box<BadgeModel>('badgesBox_$sanitizedEmail');

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      skillKey = args;
      skill = skillsBox.get(skillKey);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final p = int.tryParse(_progress.text) ?? 0;

    final note = NoteModel(
      title: _title.text,
      description: _desc.text,
      createdAt: DateTime.now(),
      skillId: skillKey,
      progressGain: p,
    );

    await notesBox.add(note);

    if (p > 0) {
      final skillToUpdate = skillsBox.get(skillKey);
      if (skillToUpdate != null) {
        skillToUpdate.progress = (skillToUpdate.progress + p).clamp(0, 100);
        await skillToUpdate.save();
      }
    }

    if (mounted) {
      // --- [+ NEW] CHECK FOR BADGES ---
      await AchievementService.checkNoteAddedBadges(notesBox, badgesBox, context);
      await AchievementService.checkSkillCompletedBadges(skillsBox, badgesBox, context);
      // --- End of Badge Check ---

      if (!mounted) return; // Re-check after awaits
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _progress.dispose();
    super.dispose();
  }

  //
  // --- HELPER METHODS MOVED HERE TO FIX ERRORS ---
  //

  /// Builds the light pink card showing skill name and progress
  Widget _buildSkillInfoCard() {
    if (skill == null) {
      return const Center(child: Text('Loading skill...'));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _lightPinkColor, // This card is styled like the "Weekly Progress"
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skill!.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Progress: ${skill!.progress}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable helper for form section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Reusable helper for text field styling
  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: _textFieldColor, // White background
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandColor, width: 2),
      ),
    );
  }

  /// Builds the "Cancel" and "Save Note" buttons at the bottom
  Widget _buildActionButtons() {
    return Row(
      children: [
        // --- Cancel Button ---
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _textFieldColor,
              foregroundColor: Colors.black54,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _borderColor),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),

        // --- Save Button ---
        Expanded(
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Save Note'),
          ),
        ),
      ],
    );
  }

  // --- END OF HELPER METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add Progress Note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Skill Info Card ---
              _buildSkillInfoCard(),
              const SizedBox(height: 24),

              // --- Note Title ---
              _buildSectionTitle('Note Title*'),
              TextFormField(
                controller: _title,
                decoration: _buildInputDecoration(
                    'e.g., Watched Figma Basics'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 24),

              // --- Description ---
              _buildSectionTitle('Description*'),
              TextFormField(
                controller: _desc,
                decoration: _buildInputDecoration('Describe what u did'),
                maxLines: 4, // Make it larger
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 24),

              // --- Progress Update ---
              _buildSectionTitle('Progress Update (%)'),
              TextFormField(
                controller: _progress,
                decoration: _buildInputDecoration(
                    'How much progress is done'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // --- Buttons ---
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}