// lib/widgets/app_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <<< ADDED
import 'package:weather_app/extension/app_extension.dart';
import 'package:weather_app/pages/forecast_page.dart';
import '../models/data/weather_data.dart';
import '../providers/settings_provider.dart'; // <<< ADDED

class AppWidgets {
  // ... buildSearchBar remains unchanged ...
  Widget buildSearchBar(
      TextEditingController controller, VoidCallback onSearch) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: const InputDecoration(
              hintText: 'Enter city name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onSearch,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text('Search', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // --- MODIFIED WIDGET for Main Screen Layout ---
  Widget buildCurrentWeatherCard(BuildContext context, WeatherData data) {

    // Access the provider to get the current setting.
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Determine the icon based on the description
    IconData weatherIcon;
    Color iconColor;

    if (data.description.toLowerCase().contains('sunny') || data.description.toLowerCase().contains('clear')) {
      weatherIcon = Icons.wb_sunny;
      iconColor = Colors.amber;
    } else if (data.description.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud;
      iconColor = Colors.blueGrey;
    } else if (data.description.toLowerCase().contains('rain')) {
      weatherIcon = Icons.umbrella;
      iconColor = Colors.indigo;
    } else {
      weatherIcon = Icons.thermostat;
      iconColor = Colors.red;
    }

    // --- CONVERT AND DISPLAY TEMPERATURE ---
    final displayedTemperature = settingsProvider.convertTemperature(data.temperature);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              data.cityName.toUpperCase(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Icon(
              weatherIcon,
              size: 120,
              color: iconColor,
            ),
            const SizedBox(height: 30),

            // Temperature (Now uses the converted value)
            Text(
              displayedTemperature,
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),

            // Description
            Text(
              data.description,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),

            // Wind Data
            Text(
              '💨 Wind: ${data.wind}',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            // 3-Days Forecast Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // The forecast page will now receive the data and use the provider for conversion
                  context.pushRoute(ForecastPage(forecastData: data.forecast));
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text('3-Days Forecast',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}