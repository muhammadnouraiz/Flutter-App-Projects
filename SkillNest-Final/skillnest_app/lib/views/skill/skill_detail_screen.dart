// File: lib/views/skill/skill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/skill_model.dart';
import '../../models/note_model.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({Key? key}) : super(key: key);

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  late final Box<SkillModel> skillsBox;
  late final Box<NoteModel> notesBox;
  SkillModel? skill;
  dynamic skillKey;

  // Define brand color
  static const Color _brandColor = Color(0xFFFF6B4A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🧠 Get the correct user-specific boxes
    final userBox = Hive.box('userBox');
    final email =
    userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');

    skillKey = ModalRoute.of(context)!.settings.arguments;
    if (skillKey != null) {
      skill = skillsBox.get(skillKey);
    }
  }

  void _deleteSkill() async {
    await skillsBox.delete(skillKey);

    // Delete related notes
    final toDelete =
    notesBox.values.where((n) => n.skillId == skillKey).toList();
    for (var n in toDelete) {
      await n.delete();
    }

    if (mounted) Navigator.pop(context);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete skill?'),
        content:
        const Text('This will also delete all notes for this skill.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _deleteSkill(); // Delete the skill
              },
              child:
              const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, SkillModel currentSkill) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: currentSkill.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Skill Name'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Skill Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newName = _nameController.text.trim();
                  currentSkill.name = newName;
                  currentSkill.save();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteNoteDialog(NoteModel note, SkillModel currentSkill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
            'This will also subtract its progress gain from the skill.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (note.progressGain != null && note.progressGain! > 0) {
                currentSkill.progress =
                    (currentSkill.progress - note.progressGain!).clamp(0, 100);
                currentSkill.save();
              }
              note.delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(NoteModel note, SkillModel currentSkill) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(text: note.title);
    final _descController = TextEditingController(text: note.description);
    final _progressController =
    TextEditingController(text: note.progressGain?.toString() ?? '0');

    final originalProgress = note.progressGain ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a title' : null,
                    ),
                    TextFormField(
                      controller: _descController,
                      decoration:
                      const InputDecoration(labelText: 'Description'),
                    ),
                    TextFormField(
                      controller: _progressController,
                      decoration: const InputDecoration(
                          labelText: 'Progress Gain (%)', suffixText: '%'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter 0 or more';
                        if (int.tryParse(val) == null) return 'Enter a number';
                        if (int.parse(val) < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newTitle = _titleController.text;
                  final newDesc = _descController.text;
                  final newProgress =
                      int.tryParse(_progressController.text) ?? 0;

                  final progressDelta = newProgress - originalProgress;

                  currentSkill.progress =
                      (currentSkill.progress + progressDelta).clamp(0, 100);
                  currentSkill.save();

                  note.title = newTitle;
                  note.description = newDesc;
                  note.progressGain = newProgress;
                  note.save();

                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Returns the correct icon based on the skill category string.
  IconData _getCategoryIcon(String category) {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: skillsBox.listenable(),
      builder: (context, Box<SkillModel> box, _) {
        final currentSkill = box.get(skillKey);

        if (currentSkill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
                child: Text('Skill not found or has been deleted.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50], // Light grey background
          appBar: AppBar(
            // [MODIFIED] Added style to make title bold
            title: Text(
              currentSkill.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.grey[50],
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black54),
                onPressed: () => _showEditNameDialog(context, currentSkill),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.black54),
                onPressed: _showDeleteDialog,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(currentSkill),
                const SizedBox(height: 24),
                _buildDescriptionCard(currentSkill),
                const SizedBox(height: 24),
                _buildNotesSection(currentSkill),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                Navigator.pushNamed(context, '/note/add', arguments: skillKey),
            backgroundColor: _brandColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Note',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  /// This card holds the progress circle and other key stats.
  Widget _buildProgressCard(SkillModel currentSkill) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = currentSkill.deadline;
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    final differenceInDays = deadlineDate.difference(today).inDays;

    String dueText;
    bool isUrgent = false;
    bool isError = false;

    if (differenceInDays == 0) {
      dueText = 'Due today';
      isUrgent = true;
      isError = deadline.isBefore(now);
    } else if (differenceInDays < 0) {
      final daysPast = differenceInDays.abs();
      dueText = 'Overdue by $daysPast day${daysPast == 1 ? '' : 's'}';
      isUrgent = true;
      isError = true;
    } else {
      dueText = 'Due in $differenceInDays day${differenceInDays == 1 ? '' : 's'}';
      isUrgent = false;
      isError = false;
    }

    final Color dueColor;
    if (isError) {
      dueColor = Colors.red;
    } else if (isUrgent) {
      dueColor = _brandColor;
    } else {
      dueColor = Colors.black54;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Category Chip
          Chip(
            label: Text(
              currentSkill.category,
              style: const TextStyle(
                  color: _brandColor, fontWeight: FontWeight.bold),
            ),
            backgroundColor: _brandColor.withOpacity(0.1),
            avatar: Icon(
              _getCategoryIcon(currentSkill.category), // Call the helper
              color: _brandColor,
            ),
          ),
          const SizedBox(height: 24),

          // Progress Circle
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (currentSkill.progress / 100).clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(_brandColor),
                ),
                Center(
                  child: Text(
                    '${currentSkill.progress}%',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (currentSkill.progress == 100)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.calendar_today,
                  color: dueColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  dueText,
                  style: TextStyle(
                    fontSize: 15,
                    color: dueColor,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  /// Builds the "Description" card
  Widget _buildDescriptionCard(SkillModel currentSkill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            currentSkill.description.isEmpty
                ? 'No description.'
                : currentSkill.description,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  /// Builds the "Notes & Logs" section (title + list)
  Widget _buildNotesSection(SkillModel currentSkill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes & Logs',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 12),

        // Note List
        ValueListenableBuilder(
          valueListenable: notesBox.listenable(),
          builder: (context, Box<NoteModel> box, _) {
            final notesForSkill =
            box.values.where((n) => n.skillId == skillKey).toList();

            if (notesForSkill.isEmpty) {
              return Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Text(
                  'No notes yet – Add your first note and watch progress grow',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notesForSkill.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = notesForSkill[i];
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (n.progressGain != null && n.progressGain! > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '+${n.progressGain}%',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 20, color: Colors.black54),
                          onPressed: () =>
                              _showEditNoteDialog(n, currentSkill),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () =>
                              _showDeleteNoteDialog(n, currentSkill),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}