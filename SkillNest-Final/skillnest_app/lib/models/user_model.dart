import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String email;

  @HiveField(1)
  String password;

  @HiveField(2)
  String bio;

  @HiveField(3)
  bool isGuest;

  UserModel({
    required this.email,
    required this.password,
    this.bio = '',
    this.isGuest = false,
  });
}
