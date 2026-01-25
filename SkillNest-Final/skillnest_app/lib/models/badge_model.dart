import 'package:hive/hive.dart';
part 'badge_model.g.dart';

// Registers this class as a Hive object with ID 3 for local storage
@HiveType(typeId: 3)
class BadgeModel extends HiveObject {

  // Field 0: Displayed as the bold header on the Achievement Card (e.g., "First Skill")
  @HiveField(0)
  String title;

  // Field 1: String path to the asset image shown in the badge grid
  @HiveField(1)
  String? iconPath;

  // Field 2: Controls UI state.
  // True = Shows full color badge. False = Shows "Locked" grey icon.
  @HiveField(2)
  bool earned;

  BadgeModel({
    required this.title,
    this.iconPath,
    this.earned = false, // Default is locked/hidden
  });
}