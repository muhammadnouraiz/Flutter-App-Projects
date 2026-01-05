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

  // This color is still needed for the icons
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
            _buildSimpleHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [REMOVED] Notifications section
                  _buildSectionTitle('Support'),
                  const SizedBox(height: 12),
                  _buildSupportCard(
                    title: 'Help & FAQ',
                    icon: Icons.help_outline,
                    onTap: () {
                      // TODO: Add navigation to Help/FAQ page
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSupportCard(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      // TODO: Add navigation to Privacy Policy page
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

  /// Builds the simple header to match the Home screen
  Widget _buildSimpleHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            // Title
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

  /// Builds the section title
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

  /// Builds the styled support/policy card
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