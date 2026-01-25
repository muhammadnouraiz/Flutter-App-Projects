import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/skill_model.dart';
import '../../models/note_model.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({super.key});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  // Database Boxes
  late final Box<SkillModel> skillsBox;
  late final Box<NoteModel> notesBox;
  SkillModel? skill;
  dynamic skillKey; // The unique ID passed from the Home Screen

  static const Color _brandColor = Color(0xFFFF6B4A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Logic: Database Setup (Similar to other screens).
    // Initializes boxes based on user email to ensure data isolation.
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');

    // Logic: Argument Retrieval.
    // Gets the specific Skill ID clicked by the user to know which data to show.
    skillKey = ModalRoute.of(context)!.settings.arguments;
    if (skillKey != null) {
      skill = skillsBox.get(skillKey);
    }
  }

  // Logic: Cascading Delete.
  // When a skill is deleted, we must also find and delete all Notes linked to it
  // to prevent "orphaned" data.
  void _deleteSkill() async {
    await skillsBox.delete(skillKey);
    final toDelete = notesBox.values.where((n) => n.skillId == skillKey).toList();
    for (var n in toDelete) {
      await n.delete();
    }
    if (mounted) Navigator.pop(context); // Go back to Home
  }

  // UI Component: Confirmation Dialog for deleting skill
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete skill?'),
        content: const Text('This will also delete all notes for this skill.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSkill();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // UI Component: Dialog to rename the skill
  void _showEditNameDialog(BuildContext context, SkillModel currentSkill) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentSkill.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Skill Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Skill Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Logic: Save new name to Hive
                  currentSkill.name = nameController.text.trim();
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

  // Logic: Delete Note & Rollback Progress.
  // If a note gave +10% progress, deleting it removes that 10% from the skill.
  void _showDeleteNoteDialog(NoteModel note, SkillModel currentSkill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This will also subtract its progress gain from the skill.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (note.progressGain != null && note.progressGain! > 0) {
                currentSkill.progress = (currentSkill.progress - note.progressGain!).clamp(0, 100);
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

  // UI Component: Complex Dialog for Editing a Note
  // Allows changing Title, Description, Progress Gain, and Deadline.
  void _showEditNoteDialog(NoteModel note, SkillModel currentSkill) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: note.title);
    final descController = TextEditingController(text: note.description);
    final progressController = TextEditingController(text: note.progressGain?.toString() ?? '0');

    DateTime? editedDeadline = note.deadline;
    final originalProgress = note.progressGain ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Note'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (val) => val == null || val.isEmpty ? 'Enter a title' : null,
                        ),
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: 'Description'),
                        ),
                        TextFormField(
                          controller: progressController,
                          decoration: const InputDecoration(labelText: 'Progress Gain (%)', suffixText: '%'),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter 0 or more';
                            if (int.tryParse(val) == null) return 'Enter a number';
                            if (int.parse(val) < 0) return 'Cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Picker Logic inside Dialog
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final lastAllowedDate = currentSkill.deadline;

                            // Validation: Note deadline cannot be after skill deadline
                            if (lastAllowedDate.isBefore(now)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skill deadline has passed. Cannot set note deadline.')));
                              return;
                            }

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editedDeadline ?? now,
                              firstDate: now,
                              lastDate: lastAllowedDate,
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
                              setState(() => editedDeadline = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: _brandColor),
                                const SizedBox(width: 8),
                                Text(
                                  editedDeadline == null
                                      ? 'Set Deadline (Optional)'
                                      : DateFormat('MMM dd, yyyy').format(editedDeadline!),
                                  style: TextStyle(color: editedDeadline == null ? Colors.grey[600] : Colors.black87),
                                ),
                                const Spacer(),
                                if (editedDeadline != null)
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () => setState(() => editedDeadline = null),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Logic: Recalculate Skill Progress
                      // Finds the difference between old progress gain and new, and updates skill.
                      final newTitle = titleController.text;
                      final newDesc = descController.text;
                      final newProgress = int.tryParse(progressController.text) ?? 0;

                      final progressDelta = newProgress - originalProgress;
                      currentSkill.progress = (currentSkill.progress + progressDelta).clamp(0, 100);
                      currentSkill.save(); // Save Skill updates

                      note.title = newTitle;
                      note.description = newDesc;
                      note.progressGain = newProgress;
                      note.deadline = editedDeadline;
                      note.save(); // Save Note updates

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper: Returns correct icon based on category string
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tech': return Icons.code;
      case 'Productivity': return Icons.auto_awesome;
      case 'Communication': return Icons.speaker_notes;
      case 'Design': return Icons.palette;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    // State Management: ValueListenableBuilder listens to the Skill Box.
    // If we rename the skill or update progress, this rebuilds the screen automatically.
    return ValueListenableBuilder(
      valueListenable: skillsBox.listenable(),
      builder: (context, Box<SkillModel> box, _) {
        final currentSkill = box.get(skillKey);
        // Error Handling: If skill was deleted elsewhere
        if (currentSkill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Skill not found or has been deleted.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(currentSkill.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.grey[50],
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              // Icons for Edit Name and Delete Skill
              IconButton(icon: const Icon(Icons.edit, color: Colors.black54), onPressed: () => _showEditNameDialog(context, currentSkill)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.black54), onPressed: _showDeleteDialog),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UI: Top Card (Circular Progress + Due Date)
                _buildProgressCard(currentSkill),
                const SizedBox(height: 24),
                // UI: Description Text
                _buildDescriptionCard(currentSkill),
                const SizedBox(height: 24),
                // UI: List of Notes associated with this skill
                _buildNotesSection(currentSkill),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // UI: FAB to Add a new note
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/note/add', arguments: skillKey),
            backgroundColor: _brandColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // UI Component: Builds the main card showing the Circular Progress Indicator
  Widget _buildProgressCard(SkillModel currentSkill) {
    // Logic: Date Calculation for "Due in X days" / "Overdue"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final deadline = currentSkill.deadline;
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final differenceInDays = deadlineDate.difference(today).inDays;

    String dueText;
    bool isUrgent = false;
    bool isError = false;

    // Logic: Determine text and color based on deadlines
    if (differenceInDays == 0) {
      dueText = 'Due today';
      isUrgent = true;
      isError = deadline.isBefore(now);
    } else if (differenceInDays < 0) {
      final daysPast = differenceInDays.abs();
      dueText = 'Overdue by $daysPast day${daysPast == 1 ? '' : 's'}';
      isUrgent = true;
      isError = true; // Red color
    } else {
      dueText = 'Due in $differenceInDays day${differenceInDays == 1 ? '' : 's'}';
      isUrgent = false;
      isError = false;
    }

    final Color dueColor = isError ? Colors.red : (isUrgent ? _brandColor : Colors.black54);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // UI: Category Chip (e.g., Tech)
          Chip(
            label: Text(currentSkill.category, style: const TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
            backgroundColor: _brandColor.withOpacity(0.1),
            avatar: Icon(_getCategoryIcon(currentSkill.category), color: _brandColor),
          ),
          const SizedBox(height: 24),
          // UI: The Big Circular Progress Bar
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
                  valueColor: const AlwaysStoppedAnimation<Color>(_brandColor),
                ),
                Center(child: Text('${currentSkill.progress}%', style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logic: Show "Completed" checkmark if 100%, otherwise show due date
          if (currentSkill.progress >= 100)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 8), Text('Completed!', style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold))])
          else
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isError ? Icons.warning_amber_rounded : Icons.calendar_today, color: dueColor, size: 18), const SizedBox(width: 8), Text(dueText, style: TextStyle(fontSize: 15, color: dueColor, fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal))]),
        ],
      ),
    );
  }

  // UI Component: Simple card displaying the description text
  Widget _buildDescriptionCard(SkillModel currentSkill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Text(currentSkill.description.isEmpty ? 'No description.' : currentSkill.description, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        ),
      ],
    );
  }

  // UI Component: The List of Notes
  Widget _buildNotesSection(SkillModel currentSkill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes & Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        // Logic: Listen to Notes Box to update list when a note is added/edited
        ValueListenableBuilder(
          valueListenable: notesBox.listenable(),
          builder: (context, Box<NoteModel> box, _) {
            // Filter: Only show notes belonging to THIS skill
            final notesForSkill = box.values.where((n) => n.skillId == skillKey).toList();

            // --- [UPDATED] Sorting Logic ---
            notesForSkill.sort((a, b) {
              // 1. If both have deadlines, sort by deadline (Ascending: nearest first)
              if (a.deadline != null && b.deadline != null) {
                return a.deadline!.compareTo(b.deadline!);
              }
              // 2. If A has deadline but B doesn't, A comes first
              if (a.deadline != null && b.deadline == null) return -1;
              // 3. If B has deadline but A doesn't, B comes first
              if (a.deadline == null && b.deadline != null) return 1;

              // 4. If neither has deadline, fallback to created date (Newest first)
              return b.createdAt.compareTo(a.createdAt);
            });

            if (notesForSkill.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Text('No notes yet – Add your first note and watch progress grow', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              );
            }

            // UI: Render List of Note Cards
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
              itemCount: notesForSkill.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = notesForSkill[i];

                bool isOverdue = false;
                if (n.deadline != null) {
                  isOverdue = n.deadline!.isBefore(DateTime.now()) &&
                      DateFormat('yMd').format(n.deadline!) != DateFormat('yMd').format(DateTime.now());
                }

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n.description),
                        if (n.deadline != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.event, size: 14, color: isOverdue ? Colors.red : Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${DateFormat('MMM dd').format(n.deadline!)}',
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // UI: Show green progress gain if > 0
                        if (n.progressGain != null && n.progressGain! > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('+${n.progressGain}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        // Edit/Delete Buttons for the Note
                        IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.black54), onPressed: () => _showEditNoteDialog(n, currentSkill)),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _showDeleteNoteDialog(n, currentSkill)),
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