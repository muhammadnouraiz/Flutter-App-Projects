// File: lib/views/main_navigation_shell.dart
import 'package:flutter/material.dart';
// NOTE: You might need to fix these import paths to match your project
import 'package:skillnest/views/home/home_screen.dart';
import 'package:skillnest/views/skill/skill_library_screen.dart';
import 'package:skillnest/views/progress/progress_tracker_screen.dart';
import 'package:skillnest/views/profile/profile_screen.dart';


// Main Shell: The parent widget that persists the Bottom Navigation Bar
// and handles switching between the 4 main tabs.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0; // Tracks which tab is active (0=Home, 1=Library, etc.)
  late final PageController _pageController; // Controls the horizontal sliding animation

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Logic: Define the list of screens corresponding to the tabs.
    // Note: We pass a callback to HomeScreen so the "See All" button there
    // can programmatically switch this shell to the Library tab (index 1).
    _screens = [
      HomeScreen(onSeeAllTapped: () => _onBottomNavTapped(1)), // Pass function
      const SkillLibraryScreen(),
      const ProgressTrackerScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Logic: Triggered when a bottom icon is tapped.
  // Uses animateToPage to slide smoothly to the selected screen.
  void _onBottomNavTapped(int index) {
    // [FIXED]
    // Replaced jumpToPage with animateToPage to get the smooth slide
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Animation speed
      curve: Curves.easeInOut, // How the animation feels
    );
  }

  // Logic: Triggered when the user swipes the screen manually.
  // Updates the bottom bar to highlight the correct icon.
  void _onPageChanged(int index) {
    // This updates the bottom bar highlight when the user swipes
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF6B4A);

    return Scaffold(
      backgroundColor: Colors.white,
      // UI Component: The container that holds the screens and allows swiping
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),

      // UI Component: The "Add Skill" Floating Action Button.
      // Logic: Only visible if we are on the Home Tab (index 0).
      // It hides automatically on other tabs.
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.pushNamed(context, '/skill/add'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Skill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4.0,
      )
          : null, // Null means no button is rendered

      // UI Component: The row of 4 icons at the bottom
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped, // This now animates
        selectedItemColor: primaryColor, // Orange when active
        unselectedItemColor: Colors.grey[600], // Grey when inactive
        type: BottomNavigationBarType.fixed, // Prevents icons from shifting size
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}