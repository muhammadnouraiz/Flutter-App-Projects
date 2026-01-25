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

// Import the main navigation shell (The container for Home, Library, Progress, Profile)
import 'views/main_navigation_shell.dart';

void main() async {
  // Logic: Startup Requirements.
  // Ensures Flutter engine is ready before we start running database code.
  WidgetsFlutterBinding.ensureInitialized();

  // Logic: Database Init.
  // Initializes Hive (NoSQL local database) for storing data on the phone.
  await Hive.initFlutter();

  // Logic: Register Adapters.
  // Tells Hive how to read/write our custom objects (User, Skill, Note, Badge).
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(SkillModelAdapter());
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(BadgeModelAdapter());

  // Logic: Global Box.
  // We only open 'userBox' here because it holds login state.
  // Specific data boxes (skills/notes) are opened later after we know WHO is logged in.
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
      debugShowCheckedModeBanner: false, // Hides the "Debug" banner

      // UI: Global Theme Configuration
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFBFC), // Light Grey Background
        fontFamily: 'Poppins', // Custom Font
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B4A)), // Orange Brand Color
        useMaterial3: true,
      ),

      // Logic: Navigation Start.
      // The app always tries to load '/' (Splash Screen) first.
      initialRoute: '/',

      // Logic: Route Map.
      // Defines all the possible screens in the app and their names.
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),

        // MAIN APP CONTAINER:
        // This holds the Bottom Navigation Bar. The Splash Screen navigates here on success.
        '/shell': (_) => const MainNavigationShell(),

        // SECONDARY SCREENS:
        // These screens get pushed ON TOP of the shell (covering the bottom nav bar).
        '/skill/add': (_) => const AddSkillScreen(),
        '/skill/detail': (_) => const SkillDetailScreen(),
        '/note/add': (_) => const AddNoteScreen(),
        '/timeline': (_) => const NotesTimelineScreen(),
        '/badges': (_) => const BadgesScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}