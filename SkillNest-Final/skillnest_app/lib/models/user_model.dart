import 'package:hive/hive.dart';
part 'user_model.g.dart';

// Registers this class as a Hive object with ID 0 (Unique ID for User)
@HiveType(typeId: 0)
class UserModel extends HiveObject {

  // Field 0: Stores user email.
  // UI: Displayed on the Profile Screen under the name.
  @HiveField(0)
  String email;

  // Field 1: Stores the password for authentication.
  // UI: Input field in Login/Signup screens (masked text).
  @HiveField(1)
  String password;

  // Field 2: A short description of the user.
  // UI: Appears as the sub-text/bio on the Profile Screen.
  @HiveField(2)
  String bio;

  // Field 3: Logic flag to check if user logged in without an account.
  // Logic: If true, skips validation. UI: Profile shows "Guest User".
  @HiveField(3)
  bool isGuest;

  UserModel({
    required this.email,
    required this.password,
    this.bio = '',
    this.isGuest = false,
  });
}