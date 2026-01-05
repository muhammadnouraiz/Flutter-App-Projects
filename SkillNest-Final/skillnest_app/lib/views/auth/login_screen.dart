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
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isPasswordObscured = true;

  /// 🧠 Utility: open user-specific Hive boxes using sanitized email.
  Future<void> _openUserSpecificBoxes(String email) async {
    final sanitizedEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // Open separate boxes for each user
    await Hive.openBox<SkillModel>('skillsBox_$sanitizedEmail');
    await Hive.openBox<NoteModel>('notesBox_$sanitizedEmail');
    await Hive.openBox<BadgeModel>('badgesBox_$sanitizedEmail');

    final userBox = Hive.box('userBox');
    await userBox.put('currentUserEmail', email);
  }

  /// 🧩 Login logic (Updated for multiple accounts)
  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final box = Hive.box('userBox');

    final allUsers = box.get('allUsers', defaultValue: <String, String>{}) as Map;

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

    if (storedPassword == _password.text) {
      // ✅ Success!
      await box.put('isLoggedIn', true);
      await box.put('isGuest', false);

      await _openUserSpecificBoxes(_email.text);

      if (mounted) {
        // [FIXED] Navigate to the '/shell' route, not '/home'
        Navigator.pushReplacementNamed(context, '/shell');
      }
    } else {
      // ❌ Password incorrect
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👤 Continue as guest
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
    const Color primaryColor = Color(0xFFFF6B4A);
    const Color screenBgColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: screenBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                // Logo
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/avatar_placeholder.png',
                    width: 70,
                    height: 70,
                  ),
                ),
                const SizedBox(height: 20),
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
                _buildTabSwitcher(context,
                    active: 'login', primaryColor: primaryColor),
                const SizedBox(height: 24),
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
                        obscureText: _isPasswordObscured,
                        validator: (v) => (v == null || v.length < 4)
                            ? 'Password must be at least 4 characters'
                            : null,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
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