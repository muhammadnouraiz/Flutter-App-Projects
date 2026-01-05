// lib/pages/forecast_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <<< ADDED
import 'package:weather_app/extension/app_extension.dart';
import 'package:weather_app/pages/settings_page.dart';
import '../models/data/weather_data.dart';
import '../providers/settings_provider.dart'; // <<< ADDED

class ForecastPage extends StatelessWidget {
  final List<ForecastData> forecastData;

  const ForecastPage({super.key, required this.forecastData});

  // Helper function for Settings Menu (for AppBar)
  void _showSettingsMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 80.0, 0.0, 0.0),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Settings',
          child: Text('Settings'),
        ),
      ],
    ).then((String? value) {
      if (value == 'Settings') {
        context.pushRoute(const SettingsPage());
      }
    });
  }

  String _getDayLabel(int index) {
    if (index == 0) return 'Tomorrow';

    final now = DateTime.now();
    final day = now.add(Duration(days: index + 1));

    return DateFormat('EEEE').format(day);
  }

  // Helper method to build each individual forecast card
  Widget _buildForecastCard(BuildContext context, ForecastData data, int index, double cardHeight) {
    final dayLabel = _getDayLabel(index);
    const Color themeColor = Colors.deepPurple;

    // Access the provider for conversion
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // --- CONVERT AND DISPLAY TEMPERATURE ---
    final displayedTemperature = settingsProvider.convertTemperature(data.temperature);

    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Day Label + Calendar Icon (Grouped on the left)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      dayLabel,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Calendar Icon (Deep Purple)
                  const Icon(Icons.calendar_month, size: 30, color: themeColor),
                ],
              ),

              const Spacer(),

              // 2. Temperature and Wind Data (Aligned Right)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Temperature (Now uses the converted value)
                  Text(
                    displayedTemperature,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // Wind
                  Row(
                    children: [
                      const Icon(Icons.air, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Wind: ${data.wind}',
                        style:
                        const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- HEIGHT CALCULATION LOGIC ---
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight;

    final totalVerticalMargin = 4 * 8.0;
    final cardsTargetHeight = (availableHeight * 0.75) - totalVerticalMargin;
    final cardHeight = cardsTargetHeight / 3.0;
    // ---------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '3-Days Forecast',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: forecastData.isEmpty
          ? const Center(
        child: Text('No forecast data available.',
            style: TextStyle(fontSize: 18)),
      )
          : Column(
        children: [
          SizedBox(height: 8.0),

          if (forecastData.length > 0)
            _buildForecastCard(context, forecastData[0], 0, cardHeight),

          if (forecastData.length > 1)
            _buildForecastCard(context, forecastData[1], 1, cardHeight),

          if (forecastData.length > 2)
            _buildForecastCard(context, forecastData[2], 2, cardHeight),

          const Spacer(),
        ],
      ),
    );
  }
}