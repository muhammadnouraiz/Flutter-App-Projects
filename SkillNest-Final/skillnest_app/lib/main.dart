// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'models/skill_model.dart';
import 'models/note_model.dart';
import 'models/badge_model.dart';

// Import all screens
import 'views/splash/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/skill/add_skill_screen.dart';
import 'views/skill/skill_detail_screen.dart';
import 'views/notes/add_note_screen.dart';
import 'views/notes/notes_timeline_screen.dart';
import 'views/achievements/badges_screen.dart';
import 'views/settings/settings_screen.dart';

// Import the main navigation shell
import 'views/main_navigation_shell.dart'; // Make sure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(SkillModelAdapter());
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(BadgeModelAdapter());

  // Only open the userBox globally
  await Hive.openBox('userBox');

  runApp(const SkillNestApp());
}


class SkillNestApp extends StatelessWidget {
  // [FIXED] Updated to use super.key for linter
  const SkillNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B4A)),
        useMaterial3: true,
      ),
      initialRoute: '/',

      // This is the correct route map
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),

        // This is the main entry point for logged-in users.
        // Your SplashScreen should navigate to '/shell' after login.
        '/shell': (_) => const MainNavigationShell(),

        // These are the "deep" screens that can be pushed on top
        '/skill/add': (_) => const AddSkillScreen(),
        '/skill/detail': (_) => const SkillDetailScreen(),
        '/note/add': (_) => const AddNoteScreen(),
        '/timeline': (_) => const NotesTimelineScreen(),
        '/badges': (_) => const BadgesScreen(),
        '/settings': (_) => const SettingsScreen(),

        // Removed '/home', '/library', '/progress', and '/profile'
        // as they are now all handled by '/shell'
      },
    );
  }
}