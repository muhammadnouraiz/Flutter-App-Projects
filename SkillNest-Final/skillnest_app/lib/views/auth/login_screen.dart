// File: lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/skill_model.dart';
import '../../models/note_model.dart';
import '../../models/badge_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  // Controllers to capture user input
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  // State variable to toggle password visibility (eye icon)
  bool _isPasswordObscured = true;

  /// 🧠 Logic: Handles Multi-User Support.
  /// It takes the email, removes special characters, and opens a specific Hive box (database)
  /// for that user. This ensures User A doesn't see User B's skills.
  Future<void> _openUserSpecificBoxes(String email) async {
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // Open separate boxes for each user
    await Hive.openBox<SkillModel>('skillsBox_$sanitizedEmail');
    await Hive.openBox<NoteModel>('notesBox_$sanitizedEmail');
    await Hive.openBox<BadgeModel>('badgesBox_$sanitizedEmail');

    final userBox = Hive.box('userBox');
    await userBox.put('currentUserEmail', email);
  }

  /// 🧩 Logic: Authentication.
  /// 1. Validates form inputs.
  /// 2. Checks if email exists in 'allUsers' map in Hive.
  /// 3. Matches password.
  /// 4. If correct, saves login state and navigates to Main App (Shell).
  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final box = Hive.box('userBox');

    final allUsers = box.get('allUsers', defaultValue: <String, String>{}) as Map;

    // Validation: Check if email exists
    if (!allUsers.containsKey(_email.text)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No account found. Please sign up.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final storedPassword = allUsers[_email.text];

    // Validation: Check password match
    if (storedPassword == _password.text) {
      // ✅ Success! Save session state.
      await box.put('isLoggedIn', true);
      await box.put('isGuest', false);

      await _openUserSpecificBoxes(_email.text);

      if (mounted) {
        // [FIXED] Navigate to the '/shell' route (Main Navigation), not '/home'
        Navigator.pushReplacementNamed(context, '/shell');
      }
    } else {
      // ❌ Error: Show red Snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👤 Logic: Guest Mode.
  /// Skips authentication and opens a generic 'guest' database box.
  Future<void> _continueAsGuest() async {
    final box = Hive.box('userBox');
    await box.put('isGuest', true);
    await box.put('isLoggedIn', true);
    await _openUserSpecificBoxes('guest'); // ✅ Guest-specific box
    if (mounted) {
      // [FIXED] Navigate to the '/shell' route, not '/home'
      Navigator.pushReplacementNamed(context, '/shell');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF6B4A); // App Orange
    const Color screenBgColor = Color(0xFF333333); // Dark Grey Background

    return Scaffold(
      backgroundColor: screenBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // UI Component: The White Card Container holding the form
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // UI Component: App Icon/Logo
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/avatar_placeholder.png',
                    width: 70,
                    height: 70,
                  ),
                ),
                const SizedBox(height: 20),
                // UI Component: "Welcome to SkillNest" Header
                const Text(
                  'Welcome to SkillNest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your learning journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // UI Component: The Login/Signup toggle tabs
                _buildTabSwitcher(context,
                    active: 'login', primaryColor: primaryColor),
                const SizedBox(height: 24),

                // UI Component: The Input Form (Email & Password)
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Email',
                        hint: 'your@example.com',
                        controller: _email,
                        primaryColor: primaryColor,
                        validator: (v) => (v == null ||
                            v.isEmpty ||
                            !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Password',
                        hint: '•••••••••',
                        controller: _password,
                        primaryColor: primaryColor,
                        obscureText: _isPasswordObscured, // Hides text if true
                        validator: (v) => (v == null || v.length < 4)
                            ? 'Password must be at least 4 characters'
                            : null,
                        // UI Component: The Eye Icon to toggle visibility
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // UI Component: The Main Orange "Continue" Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _login,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
                // UI Component: "Continue as Guest" text link
                TextButton(
                  onPressed: _continueAsGuest,
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI Component: Builds the "Login | Signup" row
  Widget _buildTabSwitcher(BuildContext context,
      {required String active, required Color primaryColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabItem('Login', active == 'login', primaryColor, () {
          if (active != 'login') {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }),
        const SizedBox(width: 40),
        _buildTabItem('Signup', active == 'signup', primaryColor, () {
          if (active != 'signup') {
            Navigator.pushReplacementNamed(context, '/signup');
          }
        }),
      ],
    );
  }

  // Helper widget for individual tab text with underline
  Widget _buildTabItem(
      String text, bool isActive, Color primaryColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget to style TextFields uniformly
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color primaryColor,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            // Default grey border
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            // Orange border when clicked
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            // Red border on error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}