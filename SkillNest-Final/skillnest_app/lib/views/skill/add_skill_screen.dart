// File: lib/views/skill/add_skill_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../../models/skill_model.dart';
// Imports for achievement logic
import '../../models/badge_model.dart';
import '../../services/achievement_service.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});
  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _form = GlobalKey<FormState>();
  // Controllers to capture user input
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _tasks = TextEditingController();

  // Default values
  String _category = 'Tech';
  DateTime? _deadline;

  // UI Colors
  final Color primaryColor = const Color(0xFFFF6B4A);
  final Color fillColor = Colors.grey[50]!;

  @override
  void dispose() {
    // Memory Management: Dispose controllers when screen closes
    _name.dispose();
    _desc.dispose();
    _tasks.dispose();
    super.dispose();
  }

  //
  // --- HELPER METHODS MOVED HERE ---
  //

  // Logic: Date Picker.
  // Opens a calendar dialog to select when the skill should be completed.
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)), // Default is next week
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // UI Styling: Applies the Orange brand color to the calendar
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _deadline = d);
  }

  // Logic: Save Functionality.
  // 1. Validates inputs.
  // 2. Opens the User's specific database box.
  // 3. Saves the new skill.
  // 4. Checks if this action unlocks any Badges.
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    // Database Setup (Multi-user isolation)
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
    final badgesBox = Hive.box<BadgeModel>('badgesBox_$sanitizedEmail');

    // Create Object
    final skill = SkillModel(
      name: _name.text,
      category: _category,
      description: _desc.text,
      progress: 0, // Starts at 0%
      deadline: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      totalTasks: int.tryParse(_tasks.text) ?? 1,
    );

    // Save to Hive
    await skillsBox.add(skill);

    if (mounted) {
      // Logic: Gamification Check.
      // E.g., if this is the 1st skill, unlock "First Skill Added" badge.
      await AchievementService.checkSkillAddedBadges(skillsBox, badgesBox, context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill added'), backgroundColor: Colors.green));
      Navigator.pop(context); // Close screen
    }
  }

  /// UI Helper: Standardizes the look of all TextFields (Rounded borders, filled color)
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    TextStyle? hintStyle,
    Icon? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
      hintText: hintText,
      hintStyle: hintStyle ?? TextStyle(color: Colors.grey[500]),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  /// UI Component: Sticky Bottom Buttons (Cancel / Add Skill)
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0).copyWith(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Add Skill Button (Orange)
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _save, // Triggers save logic
              child: const Text(
                'Add Skill',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- END OF HELPER METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match home screen background
      // UI Component: App Bar
      appBar: AppBar(
        // Consistent App Bar style
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Skill',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: Column(
          children: [
            // UI Component: Scrollable Form Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // --- Skills Name Input ---
                  TextFormField(
                    controller: _name,
                    decoration: _buildInputDecoration(
                      labelText: 'Skill Name*',
                      hintText: 'e.g. UI/UX Design',
                    ),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Category Dropdown ---
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'Tech', child: Text('Tech')),
                      DropdownMenuItem(value: 'Design', child: Text('Design')),
                      DropdownMenuItem(
                          value: 'Productivity', child: Text('Productivity')),
                      DropdownMenuItem(
                          value: 'Communication', child: Text('Communication')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'Tech'),
                    decoration: _buildInputDecoration(
                      labelText: 'Category*',
                      prefixIcon:
                      Icon(Icons.explore_outlined, color: Colors.grey[700]),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 16),

                  // --- Description Input ---
                  TextFormField(
                    controller: _desc,
                    decoration: _buildInputDecoration(
                        labelText: 'Description*',
                        hintText: 'Short description of the skill'),
                    maxLines: 4,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Total Tasks Input ---
                  TextFormField(
                    controller: _tasks,
                    decoration: _buildInputDecoration(
                      labelText: 'Total Tasks (Optional)',
                      hintText: '10',
                      suffixIcon: _tasks.text.isNotEmpty ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => _tasks.clear(),
                      ) : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}), // To update suffix icon
                  ),
                  const SizedBox(height: 16),

                  // --- Deadline Picker Field ---
                  TextFormField(
                    key: Key(_deadline.toString()), // To refresh the text
                    readOnly: true, // Prevent manual typing
                    onTap: _pickDate, // Open Calendar
                    decoration: _buildInputDecoration(
                      labelText: 'Deadline*',
                      hintText: _deadline == null
                          ? 'mm/dd/yyyy'
                          : DateFormat('MM/dd/yyyy').format(_deadline!),
                      hintStyle: TextStyle(
                        color: _deadline == null ? Colors.grey[500] : Colors.black,
                        fontSize: 16,
                      ),
                      suffixIcon: Icon(Icons.calendar_today_outlined,
                          color: Colors.grey[700]),
                    ),
                    validator: (v) =>
                    _deadline == null ? 'Please pick a deadline' : null,
                  ),
                ],
              ),
            ),
            // --- Buttons at the bottom (Add/Cancel) ---
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }
}