// File: lib/views/main_navigation_shell.dart
import 'package:flutter/material.dart';
// NOTE: You might need to fix these import paths to match your project
import 'package:skillnest/views/home/home_screen.dart';
import 'package:skillnest/views/skill/skill_library_screen.dart';
import 'package:skillnest/views/progress/progress_tracker_screen.dart';
import 'package:skillnest/views/profile/profile_screen.dart';


class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

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

  void _onBottomNavTapped(int index) {
    // [FIXED]
    // Replaced jumpToPage with animateToPage to get the smooth slide
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Animation speed
      curve: Curves.easeInOut, // How the animation feels
    );
  }

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
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
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
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped, // This now animates
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
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