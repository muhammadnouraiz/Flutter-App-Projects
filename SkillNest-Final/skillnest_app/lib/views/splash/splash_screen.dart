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
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _start();
  }

  /// Opens user-specific Hive boxes safely
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

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));

    final box = Hive.box('userBox');
    final hasSeenOnboarding =
    box.get('hasSeenOnboarding', defaultValue: false) as bool;
    final loggedIn = box.get('isLoggedIn', defaultValue: false) as bool;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else if (loggedIn) {
      final email = box.get('currentUserEmail', defaultValue: 'guest') as String;

      await _openUserSpecificBoxes(email);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/shell');
    } else {
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
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Image.asset(
            'assets/images/logo.png',
            width: 150,
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.star, size: 100, color: Color(0xFFFF6B4A));
            },
          ),
        ),
      ),
    );
  }
}
