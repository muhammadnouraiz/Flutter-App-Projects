// File: lib/views/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// [REMOVED] NotificationService import is no longer needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // [REMOVED] _notificationsOn variable
  // [REMOVED] userBox variable (was only used for notifications)

  // UI Constant: The app's primary orange color for icons
  static const Color _brandColor = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    // [REMOVED] Notification-related init logic
  }

  // [REMOVED] _toggleNotifications function

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI Component: Top Header with Back Button
            _buildSimpleHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [REMOVED] Notifications section

                  // UI Component: Support Section Header
                  _buildSectionTitle('Support'),
                  const SizedBox(height: 12),

                  // UI Component: Help & FAQ Card
                  _buildSupportCard(
                    title: 'Help & FAQ',
                    icon: Icons.help_outline,
                    onTap: () {
                      // Logic: Placeholder for future FAQ page navigation
                    },
                  ),
                  const SizedBox(height: 12),

                  // UI Component: Privacy Policy Card
                  _buildSupportCard(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      // Logic: Placeholder for future Privacy page navigation
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI Helper: Builds the top navigation bar with a back arrow
  Widget _buildSimpleHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            // Logic: Navigation. Pops the current Settings screen off the stack.
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            // Title Text
            Text(
              'Settings',
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

  /// UI Helper: Stylized section header text
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // [REMOVED] _buildNotificationCard function

  /// UI Helper: Reusable list item card for settings options
  /// Consists of a leading Icon (Orange), Title Text, and a Trailing Arrow.
  Widget _buildSupportCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withAlpha(13), // 0.05 opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: _brandColor, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}