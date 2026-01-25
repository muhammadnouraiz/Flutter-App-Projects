// File: lib/views/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/skill_model.dart';
import '../../models/note_model.dart';
import '../../models/badge_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation Controllers for the fading logo effect
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Logic: Initialize 900ms Fade-In Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward(); // Start animation

    // Logic: Trigger the navigation decision process
    _start();
  }

  /// 🧠 Logic: Database Isolation.
  /// Before going to Home, we MUST open the specific boxes for the logged-in user.
  /// This prevents errors where the app tries to read data before the box is open.
  Future<void> _openUserSpecificBoxes(String email) async {
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // Only open if not already opened
    if (!Hive.isBoxOpen('skillsBox_$sanitizedEmail')) {
      await Hive.openBox<SkillModel>('skillsBox_$sanitizedEmail');
    }
    if (!Hive.isBoxOpen('notesBox_$sanitizedEmail')) {
      await Hive.openBox<NoteModel>('notesBox_$sanitizedEmail');
    }
    if (!Hive.isBoxOpen('badgesBox_$sanitizedEmail')) {
      await Hive.openBox<BadgeModel>('badgesBox_$sanitizedEmail');
    }
  }

  /// 🧭 Logic: Navigation Decision Tree.
  /// Decides which screen to show based on user history.
  Future<void> _start() async {
    // UI: Keep logo visible for 2 seconds (Branding)
    await Future.delayed(const Duration(seconds: 2));

    final box = Hive.box('userBox');
    final hasSeenOnboarding =
    box.get('hasSeenOnboarding', defaultValue: false) as bool;
    final loggedIn = box.get('isLoggedIn', defaultValue: false) as bool;

    if (!mounted) return;

    // Check 1: Is this a brand new user? -> Go to Onboarding
    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
    // Check 2: Is user already logged in? -> Go to Home (Shell)
    else if (loggedIn) {
      final email = box.get('currentUserEmail', defaultValue: 'guest') as String;

      // Critical: Prepare data before navigating
      await _openUserSpecificBoxes(email);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/shell');
    }
    // Check 3: Otherwise -> Go to Login
    else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: Center(
        // UI Component: Animated Logo
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Image.asset(
            'assets/images/logo.png',
            width: 150,
            height: 150,
            // Fallback icon if image fails to load
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.star, size: 100, color: Color(0xFFFF6B4A));
            },
          ),
        ),
      ),
    );
  }
}