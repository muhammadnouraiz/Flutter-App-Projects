// File: lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/skill_model.dart';
import '../../models/note_model.dart';
import '../../models/badge_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Box userBox;
  late Box<SkillModel> skillBox;

  // State variables for UI display
  String email = 'guest';
  String name = 'Guest';
  int totalSkills = 0;

  // Avatar handling variables
  ImageProvider? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🧠 Logic: Data Fetching.
  /// 1. Gets the currently logged-in email.
  /// 2. Retrieves the specific Name mapped to that email.
  /// 3. Checks if a custom avatar image path exists locally.
  void _loadUserData() {
    userBox = Hive.box('userBox');

    final String currentEmail =
    userBox.get('currentUserEmail', defaultValue: 'guest') as String;

    String currentName;
    if (currentEmail == 'guest') {
      currentName = 'Guest';
    } else {
      final userNames =
      userBox.get('userNames', defaultValue: <String, String>{}) as Map;
      currentName = userNames[currentEmail] ?? 'User';
    }

    final sanitizedEmail = currentEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    skillBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');

    // Logic: Avatar Persistence.
    // Checks if the user previously saved an image path and if the file still exists on the phone.
    final String? imagePath = userBox.get('avatarPath_$currentEmail');
    ImageProvider? loadedImage;
    if (imagePath != null && File(imagePath).existsSync()) {
      loadedImage = FileImage(File(imagePath));
    }

    setState(() {
      email = currentEmail;
      name = currentName;
      totalSkills = skillBox.values.length;
      _avatarImage = loadedImage;
    });
  }

  /// 📸 Logic: Image Picker.
  /// Uses the 'image_picker' package to open the phone's gallery.
  /// Saves the selected file path to Hive so it persists after app restart.
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await userBox.put('avatarPath_$email', image.path);
        _loadUserData(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image. Check permissions.')),
        );
      }
    }
  }

  // Logic: Remove Avatar
  Future<void> _removeImage() async {
    await userBox.delete('avatarPath_$email');
    _loadUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed.')),
      );
    }
  }

  // UI Component: Bottom Sheet for Avatar options (Gallery or Remove)
  Future<void> _showImageOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (_avatarImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Remove Picture', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// ✏️ Logic: Edit Profile Name.
  /// Shows a dialog with a text field. Updates 'userNames' map in Hive if saved.
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          backgroundColor: const Color(0xFFFCF5F4),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Profile',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Name Input Field
                const Text('Name',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                      const BorderSide(color: Color(0xFFFF6B4A), width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Read-only Email Field
                const Text('Email',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: email),
                  readOnly: true, // Prevents editing email
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Cancel / Save Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black54,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            Navigator.pop(context, nameController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Save Logic: Updates Hive if name was changed
    if (newName != null && newName.isNotEmpty) {
      final userNames = Map<String, String>.from(
          userBox.get('userNames', defaultValue: <String, String>{}) as Map);
      userNames[email] = newName;
      await userBox.put('userNames', userNames);
      _loadUserData();
    }
  }

  // UI Component: Confirmation before logout
  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Are you sure?'),
          content: const Text('You will be logged out of your account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _logout();
    }
  }

  /// 🚪 Logic: Logout.
  /// 1. Closes user-specific boxes (Safety).
  /// 2. Sets 'isLoggedIn' to false in Hive.
  /// 3. Navigates back to Login Screen and removes all previous routes from stack.
  Future<void> _logout() async {
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    final notesBox = Hive.box<NoteModel>('notesBox_$sanitizedEmail');
    final badgesBox = Hive.box<BadgeModel>('badgesBox_$sanitizedEmail');

    await skillsBox.close();
    await notesBox.close();
    await badgesBox.close();

    await userBox.put('isLoggedIn', false);
    await userBox.put('isGuest', false);
    await userBox.put('currentUserEmail', null);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // UI Component: Avatar, Name, and Edit Button
            _buildSimpleHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // UI Component: Menu List Item - Badges
                  _buildMenuListItem(
                    title: 'Achievements & Badges',
                    icon: Icons.emoji_events_outlined,
                    // [FIXED] Navigate to Badges Screen
                    onTap: () {
                      Navigator.pushNamed(context, '/badges');
                    },
                  ),
                  const SizedBox(height: 12),
                  // UI Component: Menu List Item - Settings
                  _buildMenuListItem(
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 12),
                  // UI Component: Menu List Item - Logout (Red)
                  _buildMenuListItem(
                    title: 'Logout',
                    icon: Icons.logout_outlined,
                    color: Colors.red,
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI Component: Builds the top profile header.
  Widget _buildSimpleHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // UI: Avatar with Edit Pencil overlay
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFFFEEEB),
                        backgroundImage: _avatarImage,
                        child: _avatarImage == null
                            ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFFFF6B4A),
                        )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _showImageOptionsSheet,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B4A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // UI: User Name Text
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // UI: User Email Text
                  Text(
                    email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // UI: Orange "Edit Profile" Button
                  ElevatedButton(
                    onPressed: _showEditProfileDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Component: Reusable helper for list buttons (Settings, Logout, etc.)
  Widget _buildMenuListItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.black87;
    final iconColor = color ?? const Color(0xFFFF6B4A);

    return Material(
      color: const Color(0xFFFFEEEB).withAlpha(128),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: itemColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: itemColor.withAlpha(179)),
            ],
          ),
        ),
      ),
    );
  }
}