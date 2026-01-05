import 'package:hive/hive.dart';
part 'badge_model.g.dart';

@HiveType(typeId: 3)
class BadgeModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? iconPath;

  @HiveField(2)
  bool earned;

  BadgeModel({
    required this.title,
    this.iconPath,
    this.earned = false,
  });
}
