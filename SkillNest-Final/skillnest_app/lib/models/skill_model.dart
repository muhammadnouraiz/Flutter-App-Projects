import 'package:hive/hive.dart';
part 'skill_model.g.dart';

// Registers this class as a Hive object with ID 1
@HiveType(typeId: 1)
class SkillModel extends HiveObject {

  // Field 0: Displayed as the main bold title on Home Cards and Skill Detail Screen
  @HiveField(0)
  String name;

  // Field 1: Shown as a small text tag/chip (e.g., "Tech") under the skill name
  @HiveField(1)
  String category;

  // Field 2: The body text in Skill Detail screen explaining the goal
  @HiveField(2)
  String description;

  // Field 3: Integer value (0-100) that fills the Circular Progress Indicator and Linear Bars
  @HiveField(3)
  int progress;

  // Field 4: Used to calculate and display "Due in X days" text on the card
  @HiveField(4)
  DateTime deadline;

  // Field 5: Optional metric for total planned tasks (if used in logic)
  @HiveField(5)
  int totalTasks;

  SkillModel({
    required this.name,
    required this.category,
    required this.description,
    this.progress = 0,
    required this.deadline,
    required this.totalTasks,
  });
}