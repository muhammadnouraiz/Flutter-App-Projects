// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/weather_page.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      // Consumer listens only for themeMode changes
      child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Weather App',
              // Default Light Theme
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              // --- Dark Theme Definition (as requested) ---
              darkTheme: ThemeData(
                // Using a darker seed for primary elements
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
                // Setting custom colors for typical dark mode backgrounds
                scaffoldBackgroundColor: Colors.black,
                cardColor: const Color.fromARGB(255, 30, 30, 30), // Darker card color
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color.fromARGB(255, 50, 20, 100), // Darker AppBar background
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                useMaterial3: true,
              ),
              // --- Set Theme Mode dynamically from the provider ---
              themeMode: settingsProvider.themeMode,
              home: const WeatherHomePage(title: 'Weather Forecast'),
            );
          }
      ),
    );
  }
}