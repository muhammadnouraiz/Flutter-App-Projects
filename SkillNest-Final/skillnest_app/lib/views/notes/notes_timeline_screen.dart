import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../models/skill_model.dart';

class NotesTimelineScreen extends StatefulWidget {
  const NotesTimelineScreen({super.key});
  @override
  State<NotesTimelineScreen> createState() => _NotesTimelineScreenState();
}

class _NotesTimelineScreenState extends State<NotesTimelineScreen> {
  late Box<NoteModel> notesBox;
  late Box<SkillModel> skillsBox;

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
  }

  @override
  Widget build(BuildContext context) {
    final notes = notesBox.values.toList().cast<NoteModel>()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Timeline'),
        backgroundColor: const Color(0xFFFF6B4A),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final n = notes[i];
          final skill = skillsBox.get(n.skillId);

          bool isOverdue = false;
          if (n.deadline != null) {
            isOverdue = n.deadline!.isBefore(DateTime.now()) &&
                DateFormat('yMd').format(n.deadline!) != DateFormat('yMd').format(DateTime.now());
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                const SizedBox(height: 16),
                const Icon(Icons.circle, size: 12, color: Color(0xFFFF6B4A)),
                Container(width: 2, height: 100, color: Colors.grey[300])
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(n.description),

                        if (n.deadline != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: isOverdue ? Colors.red : Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${DateFormat('MMM dd').format(n.deadline!)}',
                                style: TextStyle(color: isOverdue ? Colors.red : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ],

                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(skill?.name ?? 'General', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11)),
                            Text(DateFormat('MMM dd').format(n.createdAt), style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}