import 'package:hive/hive.dart';
part 'note_model.g.dart';

@HiveType(typeId: 2)
class NoteModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  dynamic skillId; // Hive key link

  @HiveField(4)
  int? progressGain;

  // Added new optional field for deadline
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