// File: lib/views/skill/skill_library_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/skill_model.dart';

class SkillLibraryScreen extends StatefulWidget {
  const SkillLibraryScreen({super.key});

  @override
  State<SkillLibraryScreen> createState() => _SkillLibraryScreenState();
}

class _SkillLibraryScreenState extends State<SkillLibraryScreen> {
  late final Box<SkillModel> skillsBox;

  // State Variables: Track the current search text and dropdown selections
  String _search = '';
  String _filter = 'All'; // Default: Show all categories
  String _sort = 'Most Recent'; // Default: Show newest first

  static const Color _brandColor = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    // Logic: Database Setup.
    // Opens the specific 'skillsBox' for the logged-in user to show their data only.
    final userBox = Hive.box('userBox');
    final email = userBox.get('currentUserEmail', defaultValue: 'guest') as String;
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    skillsBox = Hive.box<SkillModel>('skillsBox_$sanitizedEmail');
  }

  // Helper: Returns specific icons for categories (e.g., Palette for Design)
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tech':
        return Icons.code;
      case 'Productivity':
        return Icons.auto_awesome;
      case 'Communication':
        return Icons.speaker_notes;
      case 'Design':
        return Icons.palette;
      default:
        return Icons.category;
    }
  }

  // Helper: Logic to calculate "Due in X days" string.
  // (Note: This specific helper is defined but might be used in other variations of the card).
  String _getDueDateText(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final differenceInDays = deadlineDate.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Due today';
    } else if (differenceInDays < 0) {
      final daysPast = differenceInDays.abs();
      return 'Overdue by $daysPast day${daysPast == 1 ? '' : 's'}';
    } else {
      return 'Due in $differenceInDays day${differenceInDays == 1 ? '' : 's'}';
    }
  }

  /// 🧠 Logic: Search & Filter Engine.
  /// 1. SEARCH: Filters by checking if name or category contains the search string.
  /// 2. FILTER: Keeps only skills matching the selected Category (or 'All').
  /// 3. SORT: Reorders the list based on Deadline, Progress, or Creation Time.
  List<SkillModel> _applyFilters(List<SkillModel> list) {
    var res = list;
    // Search Logic
    if (_search.isNotEmpty) {
      res = res
          .where((s) =>
      s.name.toLowerCase().contains(_search.toLowerCase()) ||
          s.category.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    // Category Filter Logic
    if (_filter != 'All') {
      res = res.where((s) => s.category == _filter).toList();
    }
    // Sorting Logic
    if (_sort == 'Deadline') {
      res.sort((a, b) => a.deadline.compareTo(b.deadline));
    } else if (_sort == 'Progress') {
      res.sort((a, b) => b.progress.compareTo(a.progress));
    } else if (_sort == 'Most Recent') {
      res = res.reversed.toList(); // Hive stores oldest first, so reverse it
    }
    return res;
  }

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      color: Colors.white, // Fixes potential black background issues
      child: Column(
        // [FIXED] Aligns children to the left
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UI Component: "Skills Library" Title
          _buildHeader(context),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // UI Component: Search Bar
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search skills or categories',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _brandColor, width: 2),
                    ),
                  ),
                  // Logic: Updates '_search' state on every keystroke
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 12),

                // UI Component: Row containing Filter and Sort Dropdowns
                Row(children: [
                  _buildStyledDropdown(
                    icon: Icons.filter_list,
                    value: _filter,
                    items: [
                      'All',
                      'Tech',
                      'Design',
                      'Productivity',
                      'Communication'
                    ],
                    onChanged: (v) => setState(() => _filter = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildStyledDropdown(
                    icon: Icons.sort,
                    value: _sort,
                    items: ['Most Recent', 'Deadline', 'Progress'],
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                ]),
              ],
            ),
          ),

          // UI Component: The Scrollable List of Skills
          Expanded(
            child: ValueListenableBuilder<Box<SkillModel>>(
              valueListenable: skillsBox.listenable(), // Listens for database changes
              builder: (context, box, _) {
                // Logic: Fetch all skills -> Apply Search/Filter -> Render
                final skills =
                _applyFilters(box.values.toList().cast<SkillModel>());

                if (skills.isEmpty) {
                  return _buildEmptyState(); // Show "No skills found"
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: skills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final s = skills[i];
                    return _buildSkillCard(s); // Render individual card
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // UI Component: Header Text
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills Library',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Component: Custom Dropdown Widget with an Icon and Box styling
  Widget _buildStyledDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            items: items.map((String item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            // Custom Builder to show Icon + Text when collapsed
            selectedItemBuilder: (BuildContext context) {
              return items.map((String item) {
                return Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item, overflow: TextOverflow.ellipsis)),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // UI Component: Shown when search returns 0 results
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No skills found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try filtering or check your search term.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // UI Component: Individual Skill Card
  Widget _buildSkillCard(SkillModel skill) {
    bool isCompleted = skill.progress == 100;

    return GestureDetector(
      // Logic: Navigate to Details Screen on tap
      onTap: () =>
          Navigator.pushNamed(context, '/skill/detail', arguments: skill.key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 opacity
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 24,
              backgroundColor: _brandColor.withAlpha(26), // 0.1 opacity
              foregroundColor: _brandColor,
              child: Icon(_getCategoryIcon(skill.category)),
            ),
            const SizedBox(width: 16),
            // Name & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${skill.category} • ${skill.deadline.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Progress Bar & Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${skill.progress}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      // Logic: Green text if 100%, otherwise Black
                      color: isCompleted ? Colors.green : Colors.black87),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: (skill.progress / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: isCompleted ? Colors.green : _brandColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}