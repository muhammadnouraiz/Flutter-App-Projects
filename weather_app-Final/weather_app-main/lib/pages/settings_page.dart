// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Units
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'UNITS',
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.grey),
              ),
            ),

            // Temperature Units Button/Card
            Card(
              elevation: 0,
              color: isDarkMode ? const Color.fromARGB(255, 30, 30, 30) : Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: settingsProvider.toggleTemperatureUnit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temperature units',
                        style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
                      ),

                      Consumer<SettingsProvider>(
                        builder: (context, provider, child) {
                          return Row(
                            children: [
                              Text(
                                provider.temperatureUnitSymbol,
                                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                              ),
                              Icon(
                                Icons.swap_vert,
                                size: 20,
                                color: isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- THEME Section Header ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'THEME',
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.grey),
              ),
            ),

            // Theme Mode Toggle Button
            Card(
              elevation: 0,
              color: isDarkMode ? const Color.fromARGB(255, 30, 30, 30) : Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black),
                    ),

                    Consumer<SettingsProvider>(
                      builder: (context, provider, child) {
                        return Switch(
                          value: provider.themeMode == ThemeMode.dark,
                          onChanged: (_) {
                            provider.toggleTheme(); // Calls the new theme toggle method
                          },
                          activeColor: Colors.deepPurple,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}