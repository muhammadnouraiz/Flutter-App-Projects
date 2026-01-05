// lib/pages/weather_page.dart

import 'package:flutter/material.dart';
import 'package:weather_app/extension/app_extension.dart';
import 'package:weather_app/pages/settings_page.dart'; // Import new SettingsPage
import '../models/api/weather_api.dart';
import '../models/data/weather_data.dart';
import '../widgets/app_widgets.dart';

class WeatherHomePage extends StatefulWidget {
  final String title;

  const WeatherHomePage({super.key, required this.title});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _fetchWeather() async {
    if (_cityController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await WeatherApi.fetchWeather(_cityController.text);
      setState(() {
        _weatherData = weatherData;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch weather data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Function to show the settings menu (the requested three dots dropdown)
  void _showSettingsMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 80.0, 0.0, 0.0), // Adjust position relative to screen
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Settings',
          child: Text('Settings'),
        ),
      ],
    ).then((String? value) {
      if (value == 'Settings') {
        // Use the extension to navigate to the SettingsPage
        context.pushRoute(const SettingsPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        // --- MODIFICATION HERE: Add the actions ---
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white), // The three dots icon
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
        // ------------------------------------------
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppWidgets().buildSearchBar(_cityController, _fetchWeather),
            20.ht,
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
            if (_weatherData != null)
              AppWidgets().buildCurrentWeatherCard(context, _weatherData!),
          ],
        ),
      ),
    );
  }
}