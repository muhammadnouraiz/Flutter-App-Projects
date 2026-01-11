import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../models/skill_model.dart';
import '../../models/badge_model.dart';
import '../../services/achievement_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _progress = TextEditingController();

  DateTime? _selectedDeadline;

  late Box<NoteModel> notesBox;
  late Box<SkillModel> skillsBox;
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
    badgesBox = Hive.box<BadgeModel>('badgesBox_$sanitizedEmail');

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      skillKey = args;
      skill = skillsBox.get(skillKey);
    }
  }

  // [FIXED] Issue 3: Restrict Note Deadline based on Skill Deadline
  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    // Determine the maximum allowed date
    // If the skill has a deadline, that is our limit. Otherwise, 5 years.
    DateTime lastAllowedDate = DateTime(now.year + 5);

    // Check if skill exists and has a deadline
    // Note: Assuming SkillModel has a 'deadline' field based on your request.
    // If SkillModel.deadline is null, we assume open-ended.
    if (skill != null && skill!.deadline != null) {
      lastAllowedDate = skill!.deadline!;
    }

    // Edge Case: If the skill deadline is already passed, alert the user
    if (lastAllowedDate.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot set deadline: The Skill deadline has already passed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now,
      lastDate: lastAllowedDate, // [FIXED] This prevents picking invalid dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _brandColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    // [FIXED] Double check validation on save just in case
    if (skill != null && skill!.deadline != null && _selectedDeadline != null) {
      if (_selectedDeadline!.isAfter(skill!.deadline!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deadline cannot be after Skill deadline.')),
        );
        return;
      }
    }

    final p = int.tryParse(_progress.text) ?? 0;
    final note = NoteModel(
      title: _title.text,
      description: _desc.text,
      createdAt: DateTime.now(),
      skillId: skillKey,
      progressGain: p,
      deadline: _selectedDeadline,
    );

    await notesBox.add(note);

    if (p > 0 && skillKey != null) {
      final skillToUpdate = skillsBox.get(skillKey);
      if (skillToUpdate != null) {
        skillToUpdate.progress = (skillToUpdate.progress + p).clamp(0, 100);
        await skillToUpdate.save();
      }
    }

    if (mounted) {
      await AchievementService.checkNoteAddedBadges(notesBox, badgesBox, context);
      await AchievementService.checkSkillCompletedBadges(skillsBox, badgesBox, context);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // --- Helper Widgets ---
  Widget _buildSkillInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _lightPinkColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(skill?.name ?? 'Skill Loading...', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (skill?.deadline != null)
            Text(
              'Skill ends: ${DateFormat('MMM dd, yyyy').format(skill!.deadline!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));
  InputDecoration _buildInputDecoration(String h) => InputDecoration(hintText: h, filled: true, fillColor: _textFieldColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _borderColor)));
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white), child: const Text('Save Note'))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Add Progress Note', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkillInfoCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Note Title*'),
              TextFormField(controller: _title, decoration: _buildInputDecoration('e.g., Finished Module 1'), validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null),
              const SizedBox(height: 24),

              // --- Deadline Picker with Validation Logic ---
              _buildSectionTitle('Deadline (Optional)'),
              InkWell(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _textFieldColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: _brandColor, size: 20),
                      const SizedBox(width: 12),
                      Text(_selectedDeadline == null ? 'No deadline set' : DateFormat('MMM dd, yyyy').format(_selectedDeadline!)),
                      const Spacer(),
                      if (_selectedDeadline != null)
                        IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedDeadline = null)),
                    ],
                  ),
                ),
              ),
              if (skill?.deadline != null && _selectedDeadline == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Must be before: ${DateFormat('MMM dd, yyyy').format(skill!.deadline!)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              _buildSectionTitle('Description*'),
              TextFormField(controller: _desc, maxLines: 3, decoration: _buildInputDecoration('What did you achieve?')),
              const SizedBox(height: 24),
              _buildSectionTitle('Progress Gain (%)'),
              TextFormField(controller: _progress, keyboardType: TextInputType.number, decoration: _buildInputDecoration('0')),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}