import 'package:hive/hive.dart';
part 'skill_model.g.dart';

@HiveType(typeId: 1)
class SkillModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  String description;

  @HiveField(3)
  int progress;

  @HiveField(4)
  DateTime deadline;

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
