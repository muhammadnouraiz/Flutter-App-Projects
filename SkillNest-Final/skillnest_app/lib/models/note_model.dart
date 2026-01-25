import 'package:hive/hive.dart';
part 'note_model.g.dart';

// Registers this class as a Hive object with ID 2
@HiveType(typeId: 2)
class NoteModel extends HiveObject {

  // Field 0: Displayed as the bold header on the Note Card (e.g., "Learnt HTML 5")
  @HiveField(0)
  String title;

  // Field 1: The main body text shown inside the note card detailing the activity
  @HiveField(1)
  String description;

  // Field 2: Used to sort notes in the "Notes Timeline" (Latest notes first)
  @HiveField(2)
  DateTime createdAt;

  // Field 3: Acts as a Foreign Key linking this note to a specific Skill parent
  @HiveField(3)
  dynamic skillId; // Hive key link

  // Field 4: Visualized as green text (e.g., "+10%") on the right side of the Note Card
  // Determines how much the skill bar increases when this note is saved.
  @HiveField(4)
  int? progressGain;

  // Added new optional field for deadline
  // Field 5: Shows a small calendar icon and date on the card if a deadline was set
  @HiveField(5)
  DateTime? deadline;

  NoteModel({
    required this.title,
    required this.description,
    required this.createdAt,
    required this.skillId,
    this.progressGain,
    this.deadline, // Added to constructor
  });
}