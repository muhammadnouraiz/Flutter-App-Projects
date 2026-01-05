// File: lib/views/notes/notes_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/note_model.dart';
import '../../models/skill_model.dart';

class NotesTimelineScreen extends StatefulWidget {
  const NotesTimelineScreen({Key? key}) : super(key: key);
  @override
  State<NotesTimelineScreen> createState() => _NotesTimelineScreenState();
}

class _NotesTimelineScreenState extends State<NotesTimelineScreen> {
  late Box<NoteModel> notesBox;
  late Box<SkillModel> skillsBox;

  @override
  void initState() {
    super.initState();

    // 🧠 Get the correct user-specific boxes
    // 1. Get the main userBox
    final userBox = Hive.box('userBox');
    // 2. Get the currently logged-in user's email (default to 'guest')
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    // 3. Sanitize the email to match the box name created at login
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // 4. Assign the correct, *already opened* boxes
    notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
  }

  @override
  Widget build(BuildContext context) {
    // This now reads from the correct user's notesBox
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
          // This now gets the skill from the correct user's skillsBox
          final skill = skillsBox.get(n.skillId);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                const SizedBox(height: 16), // Align dot with text
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF6B4A), shape: BoxShape.circle)),
                Container(
                    width: 2,
                    height: 100, // Adjust height as needed
                    color: Colors.grey[300])
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(n.description),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(skill?.name ?? 'Unknown Skill',
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic)),
                            Text(n.createdAt.toLocal().toString().split(' ')[0]),
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