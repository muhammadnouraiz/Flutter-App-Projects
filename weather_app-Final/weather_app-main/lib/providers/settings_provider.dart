// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // --- Temperature Logic ---
  bool _isCelsius = true;

  // --- Theme Logic ---
  bool _isDarkMode = false; // Default to Light Mode

  // --- Theme Getters/Setters ---
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- Temperature Getters/Setters/Logic ---
  bool get isCelsius => _isCelsius;

  String get temperatureUnitSymbol {
    return _isCelsius ? '°C' : '°F';
  }

  void toggleTemperatureUnit() {
    _isCelsius = !_isCelsius;
    notifyListeners();
  }

  String convertTemperature(String temperatureWithUnit) {
    if (temperatureWithUnit == 'N/A' || !temperatureWithUnit.contains('°')) {
      return temperatureWithUnit;
    }

    try {
      final tempString = temperatureWithUnit.replaceAll('°C', '').replaceAll('°F', '').replaceAll('+', '').trim();
      double tempValue = double.parse(tempString);

      if (_isCelsius) {
        return '${tempValue.round()}°C';
      } else {
        tempValue = (tempValue * 9 / 5) + 32;
        return '${tempValue.round()}°F';
      }
    } catch (e) {
      return temperatureWithUnit;
    }
  }
}